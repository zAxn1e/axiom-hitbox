--!strict
local LockService = require(script.Parent.LockService)
local Core = script.Parent.Parent
local Await = require(Core:WaitForChild("Await"))
local Signal = require(Core:WaitForChild("Signal"))

export type TxOp = {
	name: string,
	fn: () -> (),
	rollback: (() -> ())?,
	executed: boolean,
}

export type TxState = 
	"active" | "committing" | "aborted" | "failed" | "committed" | "finalized"


export type TransactionInternal = {
	_id: string,
	_ops: { TxOp },
	_locks: { [string]: LockService.KeyedLock },
	_state: TxState,
	_timeout: number?,
	_watchdog: thread?,
	_finalized: boolean,

	-- signals
	OnCommit: Signal.Signal<string>,
	OnAbort: Signal.Signal<string?>,
	OnFail: Signal.Signal<string>,
	OnFinally: Signal.Signal<string>,
	OnProgress: Signal.Signal<number, number, string>,

	Status: (self: TransactionInternal) -> string,
	Lock: (self: TransactionInternal, key: string) -> (),
	Do: (
		self: TransactionInternal,
		key: string,
		fn: () -> (),
		rollback: (() -> ())?,
		name: string?
	) -> (),
	Commit: (self: TransactionInternal) -> (),
	Abort: (self: TransactionInternal, reason: string?) -> (),
	Await: (self: TransactionInternal, timeout: number?) -> TxState,
}

local Transaction = {}
Transaction.__index = Transaction

local DEFAULT_TIMEOUT = 10
local Seen: { [string]: boolean } = {}

local function _finalize(self: TransactionInternal)
	if self._finalized then
		return
	end

	self._finalized = true

	-- fire
	self.OnFinally:FireSafe(self._state)

	-- cleanup signals
	self.OnCommit:Destroy()
	self.OnAbort:Destroy()
	self.OnFail:Destroy()
	self.OnFinally:Destroy()
	self.OnProgress:Destroy()
end

function Transaction.new(id: string?, timeout: number?): TransactionInternal
	local tx: TransactionInternal = {
		_id = id or tostring(os.clock()),
		_ops = {},
		_locks = {},
		_state = "active" :: TxState,
		_timeout = timeout or DEFAULT_TIMEOUT,
		_watchdog = nil,
		_finalized = false,

		-- signals
		OnCommit = Signal.new(),
		OnAbort = Signal.new(),
		OnFail = Signal.new(),
		OnFinally = Signal.new(),
		OnProgress = Signal.new(),

		Status = Transaction.Status,
		Lock = Transaction.Lock,
		Do = Transaction.Do,
		Commit = Transaction.Commit,
		Abort = Transaction.Abort,
		Await = Transaction.Await,
	}

	-- watchdog timeout
	if tx._timeout then
		tx._watchdog = task.spawn(function()
			task.wait(tx._timeout :: number)

			if tx._state ~= "active" then
				return
			end

			tx:Abort("timeout")
		end)
	end

	return tx
end

function Transaction.Status(self: TransactionInternal): string
	return self._state
end

function Transaction.Lock(self: TransactionInternal, key: string)
	if self._state ~= "active" then
		error("[Transaction] lock() when state=" .. self._state, 2)
	end

	local orderedKey = "tx:" .. key

	if self._locks[orderedKey] then
		return
	end

	-- sort keys
	local keys = {}
	for k in pairs(self._locks) do
		table.insert(keys, k)
	end
	table.insert(keys, orderedKey)
	table.sort(keys)

	-- acquire in sorted order
	for _, k in ipairs(keys) do
		if not self._locks[k] then
			local lk = LockService:GetLock(k)
			lk:Acquire(self._timeout or 10)
			self._locks[k] = lk
		end
	end
end

function Transaction.Do(
	self: TransactionInternal,
	key: string,
	fn: () -> (),
	rollback: (() -> ())?,
	name: string?
)
	if self._state ~= "active" then
		error("[Transaction] Do() when state=" .. self._state, 2)
	end

	self:Lock(key)

	table.insert(self._ops, {
		name = name or key,
		fn = fn,
		rollback = rollback,
		executed = false,
	})
end

function Transaction.Await(self: TransactionInternal, timeout: number?): TxState
	if self._finalized then
		return self._state
	end

	local state = Await.Signal(self.OnFinally, timeout)

	return state :: TxState
end

function Transaction.Abort(self: TransactionInternal, reason: string?)
	if self._state ~= "active" and self._state ~= "committing" then
		return
	end

	(self :: TransactionInternal)._state = "aborted"

	if self._watchdog then
		pcall(task.cancel, self._watchdog)
		self._watchdog = nil
	end

	for i = #self._ops, 1, -1 do
		local op = self._ops[i]
		if op.executed and op.rollback then
			pcall(op.rollback)
		end
	end

	for _, lk in pairs(self._locks) do
		lk:Release()
	end

	Seen[self._id] = nil
	table.clear(self._locks)

	self.OnAbort:FireSafe(reason)

	_finalize(self)
end

function Transaction.Commit(self: TransactionInternal)
	if self._state ~= "active" then
		error("[Transaction] commit() but state=" .. self._state, 2)
	end

	if Seen[self._id] then
		error("[Transaction] duplicate commit id=" .. self._id)
	end
	Seen[self._id] = true

	if self._watchdog then
		pcall(task.cancel, self._watchdog)
		self._watchdog = nil
	end

	self._state = "committing"

	local total = #self._ops
	local index = 0

	local ok, err = pcall(function()
		for _, op in ipairs(self._ops) do
			index += 1

			-- progress event
			self.OnProgress:FireSafe(index, total, op.name)

			op.executed = true
			op.fn()
		end
		return nil
	end)

	if not ok then
		self._state = "failed"

		for i = #self._ops, 1, -1 do
			local op = self._ops[i]
			if op.executed and op.rollback then
				pcall(op.rollback)
			end
		end

		for _, lk in pairs(self._locks) do
			lk:Release()
		end

		Seen[self._id] = nil
		table.clear(self._locks)

		self.OnFail:FireSafe(tostring(err))

		_finalize(self)

		error(err, 2)
	end

	for _, lk in pairs(self._locks) do
		lk:Release()
	end

	table.clear(self._locks)

	self._state = "committed"

	self.OnCommit:FireSafe(self._id)

	_finalize(self)
end

return Transaction