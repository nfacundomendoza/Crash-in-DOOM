version "4.14"
class IdentityChecks : EventHandler
{
    double shortHeight;
    double fullHeight;
    Actor launched;
    Vector3 launchOrigin;
    Vector3 deathCamera;
    override void WorldTick()
    {
        let p=CrashPlayer(players[0].mo);
        if (!p) return;
        if (level.time==5)
        {
            let it=ThinkerIterator.Create('Actor'); Actor a; int fruits=0;int heals=0;
            while ((a=Actor(it.Next()))!=null)
            {
                if (a is 'CrashWumpa') fruits++;
                if (a is 'Health' || a is 'Soulsphere' || a is 'Megasphere') heals++;
                if (a.bISMONSTER || a is 'CrashAkuCrate') a.Destroy();
            }
            Console.Printf("IDENTITY health_replaced=%d fruits=%d original_heals=%d",fruits>0 && heals==0,fruits,heals);
        }
        if (level.time==15)
        {
            p.health=50;p.player.health=50;
            let fruit=CrashWumpa(Actor.Spawn('CrashWumpa',p.Pos));fruit.healAmount=25;
            p.TryMove(p.Pos.XY+(1,0),1);
            let counter=p.FindInventory('CrashWumpaCounter');
            Console.Printf("IDENTITY fruit_heals=%d counter=%d sound=%d",p.health==75,counter?counter.Amount:0,p.IsActorPlayingSound(CHAN_ITEM,Sound("crash/wumpa")));
        }
        if (level.time==25)
        {
            p.health=100;p.player.health=100;
            Actor.Spawn('CrashWumpa',p.Pos);p.TryMove(p.Pos.XY+(1,0),1);
            let counter=p.FindInventory('CrashWumpaCounter');
            Console.Printf("IDENTITY counts_at_full_health=%d",counter && counter.Amount==2);
        }
        if (level.time>=80 && level.time<130) shortHeight=max(shortHeight,p.Pos.Z-p.FloorZ);
        if (level.time>=135 && level.time<185) fullHeight=max(fullHeight,p.Pos.Z-p.FloorZ);
        if (level.time==190)
            Console.Printf("IDENTITY variable_jump=%d short=%.2f full=%.2f",shortHeight>0 && fullHeight>shortHeight+30,shortHeight,fullHeight);
        if (level.time==210)
        {
            for (int angle=0;angle<360 && !launched;angle+=45)
            {
                Vector2 at=p.Pos.XY+(cos(angle)*44,sin(angle)*44);
                if (p.CheckMove(at)) launched=Actor.Spawn('ZombieMan',(at.X,at.Y,p.FloorZ));
            }
            if (launched)
            {
                launched.ReactionTime=500;launchOrigin=launched.Pos;
                p.SpinHit();
                Console.Printf("IDENTITY enemy_launch=%d vz=%.1f launch_sound=%d",launched.health<=0 && launched.Vel.Z>0,launched.Vel.Z,launched.IsActorPlayingSound(CHAN_BODY,Sound("crash/launch")));
            }
        }
        if (level.time==220 && launched)
            Console.Printf("IDENTITY corpse_moved=%d valid_sector=%d",(launched.Pos-launchOrigin).Length()>10,launched.CurSector!=null);
        if (level.time==225)
        {
            p.DamageMobj(null,null,5,'Normal');
            Console.Printf("IDENTITY crash_pain=%d cooldown=%d",p.IsActorPlayingSound(CHAN_VOICE,Sound("crash/hurt")),p.hurtCooldown);
        }
        if (level.time==230)
        {
            int before=p.hurtCooldown;p.DamageMobj(null,null,5,'Normal');
            Console.Printf("IDENTITY pain_not_restarted=%d",p.hurtCooldown<=before && p.hurtCooldown>0);
        }
        if (level.time==270) p.DamageMobj(null,null,10000,'Normal',DMG_FORCED);
        if (level.time==272 && p.thirdPersonCamera) deathCamera=p.thirdPersonCamera.Pos;
        if (level.time==280) p.SetOrigin(p.Pos+(0,0,16),false);
        if (level.time==340)
            Console.Printf("IDENTITY death_animation=%d frame=%d camera_fixed=%d",p.frame==19,p.frame,p.thirdPersonCamera && p.thirdPersonCamera.deathLocked && (p.thirdPersonCamera.Pos-deathCamera).Length()<0.01);
    }
}
