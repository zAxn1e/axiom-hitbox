--!strict

export type Mailbox = {
    Send: (self: Mailbox, fn: () -> ()) -> (),
    Size: (self: Mailbox) -> number,
}

local MAX_QUEUE = 200 -- configurable

local Actor = {}
local mailboxes: { [any]: Mailbox } = {}

function Actor.ForKey(key: any): Mailbox
    local existing = mailboxes[key]
    if existing then return existing end

    local queue: { () -> () } = {}
    local running = false
    local box: any = {}
    local maxObserved = 0

    local function run()
        if running then return end
        running = true

        while #queue > 0 do
            local job = table.remove(queue, 1) :: () -> ()
            local ok, err = pcall(function()
                job()
                return nil
            end)

            if not ok then
                warn("[Actor] job error:", err)
            end
        end

        running = false
    end

    function box:Send(fn: () -> ())
        if #queue >= MAX_QUEUE then
            warn("[Actor] queue overflow for key=", key, " dropped job")
            return
        end

        table.insert(queue, fn)

        if #queue > maxObserved then
            maxObserved = #queue
            if maxObserved % 50 == 0 then
                warn("[Actor] high backlog key=", key, " size=", maxObserved)
            end
        end

        task.defer(run)
    end

    function box:Size(): number
        return #queue
    end

    mailboxes[key] = box :: Mailbox
    return box
end

return Actor