version "4.14"
class OrientationChecks : EventHandler
{
    Actor supportedEnemy;
    bool supportedKilled;
    bool supportedBounce;
    double cameraYaw;
    override void WorldTick()
    {
        let p=CrashPlayer(players[0].mo);
        if (!p) return;
        if (level.time==5)
        {
            let it=ThinkerIterator.Create('Actor'); Actor a;
            while ((a=Actor(it.Next()))!=null)
                if (a.bISMONSTER || a is 'CrashAkuCrate') a.Destroy();
            p.GiveInventory('CrashAkuPickup',1);
            cameraYaw=p.Angle;
        }
        if (level.time==20)
        {
            supportedEnemy=Actor.Spawn('DoomImp',(p.Pos.X,p.Pos.Y,p.FloorZ));
            supportedEnemy.ReactionTime=500;
            p.SetOrigin((p.Pos.X,p.Pos.Y,supportedEnemy.Pos.Z+supportedEnemy.Height+0.05),false);
            // This slow contact is outside the previous descending-speed test.
            // Native support detection must handle it instead of leaving a platform.
            p.Vel=(0,0,-0.1);
            p.bONMOBJ=false;
        }
        if (supportedEnemy && supportedEnemy.health<=0) supportedKilled=true;
        if (level.time>20 && level.time<70 && p.Vel.Z>0 && p.stompCount>0) supportedBounce=true;
        if (level.time==70)
        {
            Console.Printf("ORIENTATION support_killed=%d bounced=%d",supportedKilled,supportedBounce);
            if (supportedEnemy) supportedEnemy.Destroy();
        }
        if (level.time==125)
            Console.Printf("ORIENTATION lateral=%d offset=%.1f camera_unchanged=%d",abs(p.SpriteRotation)>65 && abs(p.SpriteRotation)<115,p.SpriteRotation,p.Angle==cameraYaw);
        if (level.time==190)
        {
            let maskIt=ThinkerIterator.Create('CrashAkuOrbit');
            let mask=CrashAkuOrbit(maskIt.Next());
            Console.Printf("ORIENTATION back_faces_camera=%d offset=%.1f camera_unchanged=%d mask_lower=%d",abs(p.SpriteRotation)>155,p.SpriteRotation,p.Angle==cameraYaw,mask && mask.Pos.Z-p.Pos.Z<27);
        }
    }
}
