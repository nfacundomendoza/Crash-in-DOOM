version "4.14"
class CounterSaveChecks : EventHandler
{
    bool restored;
    override void WorldLoaded(WorldEvent e) { restored=e.IsSaveGame; }
    override void WorldTick()
    {
        let p=players[0].mo;
        if (!p) return;
        if (level.time==5 && !restored) p.GiveInventory('CrashWumpaCounter',7);
        if (restored && level.time==81)
        {
            let count=p.FindInventory('CrashWumpaCounter');
            Console.Printf("IDENTITY saved_counter=%d amount=%d",count && count.Amount==7,count?count.Amount:0);
        }
    }
}
