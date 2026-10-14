version "4.14"
class CrashChecks : EventHandler
{
    override void WorldTick()
    {
        let p = CrashPlayer(players[0].mo);
        if (!p) return;
        if (level.time == 20)
        {
            int blocked = 0;
            for (int a=0; a<360; a+=45)
            {
                for (int d=32; d<=256; d+=32)
                {
                    if (!p.CheckMove(p.Pos.XY + (cos(a)*d, sin(a)*d))) blocked++;
                }
            }
            Console.Printf("CRASH_CHECK hull=%d walls=%d sector=%d", p.Radius==16 && p.Height==56, blocked, p.CurSector!=null);
            Actor target = null;
            for (int a=0; a<360 && target==null; a+=45)
            {
                vector2 dest = p.Pos.XY + (cos(a)*44, sin(a)*44);
                if (p.CheckMove(dest)) target = Actor.Spawn('DoomImp', (dest.X,dest.Y,p.Pos.Z));
            }
            if (target)
            {
                target.ReactionTime=200;
                int before=target.health;
                p.SpinHit();
                Console.Printf("CRASH_CHECK spin_damage=%d before=%d after=%d", target.health<before, before,target.health);
                target.Destroy();
            }
            for (int a=0; a<360; a+=45)
            {
                vector2 dest = p.Pos.XY + (cos(a)*44, sin(a)*44);
                if (p.CheckMove(dest)) continue;
                let behind = Actor.Spawn('DoomImp', (dest.X,dest.Y,p.Pos.Z));
                if (!behind) continue;
                behind.ReactionTime=200;
                if (!p.CheckSight(behind))
                {
                    int before=behind.health;
                    p.SpinHit();
                    Console.Printf("CRASH_CHECK wall_protects=%d before=%d after=%d",behind.health==before,before,behind.health);
                    behind.Destroy();
                    break;
                }
                behind.Destroy();
            }
        }
        if (level.time == 275)
        {
            for (int a=0; a<360; a+=45)
            {
                vector2 dest = p.Pos.XY + (cos(a)*44, sin(a)*44);
                if (p.CheckMove(dest)) continue;
                let behind = Actor.Spawn('DoomImp', (dest.X,dest.Y,p.Pos.Z));
                if (!behind) continue;
                behind.ReactionTime=200;
                if (!p.CheckSight(behind))
                {
                    int before=behind.health;
                    p.SpinHit();
                    Console.Printf("CRASH_CHECK wall_protects=%d before=%d after=%d",behind.health==before,before,behind.health);
                    behind.Destroy();
                    break;
                }
                behind.Destroy();
            }
        }
        if (level.time % 10 == 0)
        {
            Console.Printf("CRASH_STATE tic=%d x=%.2f y=%.2f z=%.2f floor=%.2f vz=%.2f spin=%d",level.time,p.Pos.X,p.Pos.Y,p.Pos.Z,p.FloorZ,p.Vel.Z,p.spinRemaining);
        }
    }
}
