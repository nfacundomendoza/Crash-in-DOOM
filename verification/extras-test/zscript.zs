version "4.14"
class ExtrasChecks : EventHandler
{
    double ground;
    double maxHeight;
    double startX;
    double startY;
    bool sawFlip;
    bool sawSpin;
    bool sawSpinSound;
    bool damageBlocked;
    override void WorldTick()
    {
        let p = CrashPlayer(players[0].mo);
        if (!p) return;
        if (level.time==5)
        {
            // Remove combat only from the verification fixture to isolate motion.
            let enemies=ThinkerIterator.Create('Actor');
            Actor a;
            while ((a=Actor(enemies.Next()))!=null)
                if (a.bISMONSTER) a.Destroy();
            ground=p.FloorZ; startX=p.Pos.X; startY=p.Pos.Y;
            int count=0;int valid=0;
            let boxes=ThinkerIterator.Create('CrashAkuCrate');
            CrashAkuCrate box;
            while ((box=CrashAkuCrate(boxes.Next()))!=null)
            {
                count++;
                if (box.CheckPosition(box.Pos.XY) && box.Pos.Z==box.FloorZ) valid++;
                Console.Printf("BOX x=%.1f y=%.1f z=%.1f",box.Pos.X,box.Pos.Y,box.Pos.Z);
            }
            int blocked=0;
            for (int a=0; a<360; a+=45)
                for (int d=32;d<=256;d+=32)
                    if (!p.CheckMove(p.Pos.XY+(cos(a)*d,sin(a)*d))) blocked++;
            Console.Printf("EXTRA placement=%d count=%d valid=%d hull=%d walls=%d",count>0 && count==valid,count,valid,p.Radius==16 && p.Height==56,blocked);
        }
        if (level.time==20)
        {
            Actor crate=null;
            for (int a=0;a<360 && !crate;a+=45)
            {
                Vector2 at=p.Pos.XY+(cos(a)*44,sin(a)*44);
                if (p.CheckMove(at)) crate=Actor.Spawn('CrashAkuCrate',(at.X,at.Y,p.Pos.Z));
            }
            if (crate)
            {
                p.SpinHit();
                Console.Printf("EXTRA spin_breaks_crate=%d",crate.health<=0);
                crate.Destroy();
            }
            let pickups=ThinkerIterator.Create('CrashAkuPickup');
            let pickup=CrashAkuPickup(pickups.Next());
            Console.Printf("EXTRA crate_drops_mask=%d",pickup!=null);
            if (pickup)
            {
                // A native collision move must collect the dropped pickup.
                bool moved=p.TryMove(pickup.Pos.XY,1);
                let power=CrashAkuPower(p.FindInventory('CrashAkuPower'));
                bool accepted=moved && power!=null;
                int before=p.health;
                p.DamageMobj(null,null,20,'Normal');
                damageBlocked=p.health==before;
                Console.Printf("EXTRA pickup=%d invulnerable=%d duration=%d damage_blocked=%d",accepted,p.bINVULNERABLE,power?power.EffectTics:0,damageBlocked);
            }
        }
        if (level.time>20 && level.time<700)
        {
            let power=CrashAkuPower(p.FindInventory('CrashAkuPower'));
            if (level.time==40)
                Console.Printf("EXTRA orbit=%d",power && power.mask && power.mask.Target==p);
        }
        if (p.Pos.Z-p.FloorZ>maxHeight) maxHeight=p.Pos.Z-p.FloorZ;
        if (p.sprite==Actor.GetSpriteIndex('CRJP') && p.frame>=8) sawFlip=true;
        if (p.spinRemaining>0) sawSpin=true;
        if (p.spinRemaining>0 && p.IsActorPlayingSound(CHAN_BODY,Sound("crash/spin"))) sawSpinSound=true;
        if (level.time==750)
        {
            int before=p.health;
            p.DamageMobj(null,null,20,'Normal');
            int orbits=0;
            let orbitIt=ThinkerIterator.Create('CrashAkuOrbit');
            while (orbitIt.Next()!=null) orbits++;
            Console.Printf("EXTRA expired=%d damage_restored=%d orphan_masks=%d",!p.FindInventory('CrashAkuPower') && !p.bINVULNERABLE,p.health<before,orbits);
            Console.Printf("EXTRA jump_height=%.2f flip=%d landed=%d spin_input=%d spin_sound=%d sector=%d",maxHeight,sawFlip,p.Pos.Z<=p.FloorZ+.5 || p.bONMOBJ,sawSpin,sawSpinSound,p.CurSector!=null);
        }
    }
}

