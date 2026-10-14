version "4.14"
class FeelChecks : EventHandler
{
    Actor crate;
    Actor enemy;
    Actor sideEnemy;
    int stompBefore;
    bool crateBounce;
    bool crateBroken;
    bool enemyBounce;
    bool airSteered;
    bool airReversed;
    bool spinSound;
    override void WorldTick()
    {
        let p=CrashPlayer(players[0].mo);
        if (!p) return;
        if (level.time==5)
        {
            let it=ThinkerIterator.Create('Actor');Actor a;
            while ((a=Actor(it.Next()))!=null)
                if (a.bISMONSTER || a is 'CrashAkuCrate') a.Destroy();
            p.GiveInventory('CrashAkuPickup',1);
        }
        if (level.time==20)
        {
            crate=Actor.Spawn('CrashAkuCrate',(p.Pos.X,p.Pos.Y,p.FloorZ));
            double feet=min(crate.Pos.Z+crate.Height+32,p.CeilingZ-p.Height-2);
            p.SetOrigin((p.Pos.X,p.Pos.Y,feet),false);
            p.Vel=(0,0,-2);p.bONMOBJ=false;stompBefore=p.stompCount;
        }
        if (level.time>20 && level.time<55)
        {
            if (crate && crate.health<=0) crateBroken=true;
            if (p.Vel.Z>0 && p.stompCount>stompBefore) crateBounce=true;
        }
        if (level.time==55)
            Console.Printf("FEEL crate_stomp=%d bounce=%d count=%d",crateBroken,crateBounce,p.stompCount);
        if (level.time==65)
        {
            p.SetOrigin((p.Pos.X,p.Pos.Y,p.FloorZ),false);p.Vel=(0,0,0);
            enemy=Actor.Spawn('DoomImp',p.Pos);
            enemy.ReactionTime=500;
            double feet=min(enemy.Pos.Z+enemy.Height+20,p.CeilingZ-p.Height-2);
            p.SetOrigin((p.Pos.X,p.Pos.Y,feet),false);
            p.Vel=(0,0,-2);p.bONMOBJ=false;stompBefore=p.stompCount;
        }
        if (level.time>65 && level.time<100 && p.Vel.Z>0 && p.stompCount>stompBefore) enemyBounce=true;
        if (level.time==100)
        {
            Console.Printf("FEEL enemy_stomp=%d bounce=%d",enemy && enemy.health<=0,enemyBounce);
            if (enemy) enemy.Destroy();
        }
        if (level.time==115)
        {
            p.SetOrigin((p.Pos.X,p.Pos.Y,p.FloorZ+10),false);p.Vel=(0,0,-2);
            sideEnemy=Actor.Spawn('DoomImp',(p.Pos.X+40,p.Pos.Y,p.FloorZ));
            sideEnemy.ReactionTime=500;
        }
        if (level.time==130)
        {
            Console.Printf("FEEL side_contact_safe=%d",sideEnemy && sideEnemy.health==60);
            if (sideEnemy) sideEnemy.Destroy();
        }
        if (level.time>=155 && level.time<180 && p.Pos.Z>p.FloorZ+1 && p.Vel.XY.Length()>1) airSteered=true;
        if (level.time>=165 && level.time<180 && p.Pos.Z>p.FloorZ+1)
        {
            // Native camera-relative right direction is Angle-90.
            if (p.Vel.X*cos(p.Angle-90)+p.Vel.Y*sin(p.Angle-90)>0.5) airReversed=true;
        }
        if (p.spinRemaining>0 && p.IsActorPlayingSound(CHAN_BODY,Sound("crash/spin"))) spinSound=true;
        if (level.time==230)
            Console.Printf("FEEL air_steering=%d air_reversal=%d spin_sound=%d hull=%d sector=%d",airSteered,airReversed,spinSound,p.Radius==16 && p.Height==56,p.CurSector!=null);
    }
}
