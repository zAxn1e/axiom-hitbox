--!strict
local Transaction = require(script.Parent.Transaction)

export type TradeOp = {
    key: string,
    fn: () -> (),
    undo: (() -> ())?
}

export type TradeInternal = {
    _id: string,
    _ops: { TradeOp },
    _tx: any,

    Add: (self: TradeInternal, resourceKey: string, fn: () -> (), undo: (() -> ())?) -> (),
    Commit: (self: TradeInternal) -> (),
}

local Trade = {}
Trade.__index = Trade

local active: { [string]: boolean } = {}

function Trade.Begin(tradeId: string): TradeInternal
    active[tradeId] = true

    local self: any = setmetatable({}, Trade)

    self._id = tradeId
    self._ops = {}
    self._tx = Transaction.new(tradeId)

    return self :: TradeInternal
end

function Trade:Add(resourceKey: string, fn: () -> (), undo: (() -> ())?)
    local selfInternal = self :: TradeInternal

    table.insert(selfInternal._ops, {
        key = resourceKey,
        fn = fn,
        undo = undo,
    })
end

function Trade:Commit()
    local selfInternal = self :: TradeInternal

    for _, op in ipairs(selfInternal._ops) do
        selfInternal._tx:Do(
            op.key,
            op.fn,
            op.undo
        )
    end

    selfInternal._tx:Commit()
    active[selfInternal._id] = nil
end

return Trade