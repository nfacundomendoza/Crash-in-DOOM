version "4.14"
class CrashPlayer : DoomPlayer
{
    int spinRemaining;
    int spinCooldown;
    int visualClock;
    int airClock;
    int deathClock;
    bool spinHeld;
    CrashCamera thirdPersonCamera;
    int stompCount;
    double visualFacing;
    bool facingInitialized;
    int hurtCooldown;
    bool jumpHeld;
    bool controlledJump;
    bool deathStarted;
    bool wasGrounded;
    int danceRemaining;
    int danceHealth;
    bool danceHeld;
    double deathAngle;
    double deathPitch;
    double deathFacing;

    Default
    {
        Player.DisplayName "Crash Bandicoot";
        Player.SoundClass "crash";
        Player.JumpZ 14.5;
        Radius 16;
        Height 56;
        // The Doom player collision hull is retained. Movement stays native.
        Speed 0.85;
    }

    override void DeathThink()
    {
        // The native death handler turns toward the killer and accepts early respawn.
        // Keep presentation fixed and restart through the native single-player path.
        if (!player) return;
        TickPSprites();
        if (player.damagecount>0) player.damagecount--;
        if (deathStarted)
        {
            Angle=deathAngle;
            Pitch=deathPitch;
            SpriteRotation=deathFacing;
        }
        if (deathClock>=70)
            player.playerstate=multiplayer?PST_REBORN:PST_ENTER;
    }

    override void ApplyAirControl(out double movefactor, out double bobfactor)
    {
        // Strong steering is specific to Crash; world and actor collisions stay native.
        movefactor *= 0.65;
        bobfactor *= 0.65;
    }

    override void MovePlayer()
    {
        Super.MovePlayer();
        if (!player || player.mo!=self || player.onground || waterlevel || bNOGRAVITY) return;
        // The original GOOL controller updates horizontal velocity from the D-pad
        // even in the air. Reduce Doom's coasting to allow braking and reversing.
        Vel.X *= 0.90;
        Vel.Y *= 0.90;
        double speed = Vel.XY.Length();
        if (speed > 12)
        {
            Vel.X *= 12/speed;
            Vel.Y *= 12/speed;
        }
    }

    override void Tick()
    {
        double oldFeet = Pos.Z;
        double downward = Vel.Z;
        Super.Tick();
        if (hurtCooldown>0) hurtCooldown--;
        if (player && player.mo==self && health>0)
        {
            bool jumpDown=(player.cmd.buttons & BT_JUMP)!=0;
            if ((wasGrounded || oldFeet<=FloorZ+0.5) && Vel.Z>0 && jumpDown && !jumpHeld) controlledJump=true;
            if (controlledJump && jumpHeld && !jumpDown && Vel.Z>4.5) Vel.Z=4.5;
            if (Vel.Z<=0 || Pos.Z<=FloorZ || bONMOBJ) controlledJump=false;
            jumpHeld=jumpDown;
            wasGrounded=Pos.Z<=FloorZ+0.5 || bONMOBJ;
        }
        if (health>0 && player && player.mo==self && (downward < -0.5 || bONMOBJ))
            TryStomp(oldFeet, bONMOBJ);
        if (health>0 && player && player.mo==self) UpdateVisualFacing();
        if (health>0 && player && player.mo == self)
        {
            let preference = CVar.GetCVar('crash_thirdperson', player);
            bool third = preference == null || preference.GetBool();
            if (third)
            {
                if (!thirdPersonCamera)
                {
                    thirdPersonCamera = CrashCamera(Spawn('CrashCamera', Pos));
                    thirdPersonCamera.Target = self;
                }
                player.cheats &= ~CF_CHASECAM;
                player.camera = thirdPersonCamera;
            }
            else if (player.camera == thirdPersonCamera) player.camera = self;
        }
        visualClock++;
        if (health <= 0)
        {
            danceRemaining=0;
            if (!deathStarted)
            {
                deathStarted=true;
                deathAngle=Angle; deathPitch=Pitch; deathFacing=SpriteRotation;
                if (thirdPersonCamera) thirdPersonCamera.LockDeathView();
            }
            // The Death state alone advances model frames, preserving interpolation.
            Angle=deathAngle; Pitch=deathPitch; SpriteRotation=deathFacing;
            Vel.X=0; Vel.Y=0;
            deathClock++;
            return;
        }
        if (!player || player.mo != self) return;
        if (spinCooldown > 0) spinCooldown--;
        bool held = (player.cmd.buttons & BT_USER1) != 0;
        if (held && !spinHeld && spinCooldown == 0)
        {
            spinRemaining = 14;
            spinCooldown = 24;
            A_StartSound("crash/spin", CHAN_BODY, volume: 0.9);
            SpinHit();
        }
        spinHeld = held;
        bool danceDown=(player.cmd.buttons & BT_USER2)!=0;
        bool danceBlocked=player.cmd.forwardmove!=0 || player.cmd.sidemove!=0 ||
            (player.cmd.buttons & (BT_JUMP|BT_ATTACK|BT_ALTATTACK|BT_USER1))!=0 ||
            Pos.Z>FloorZ+0.5 || Vel.XY.Length()>0.4 || spinRemaining>0;
        if (danceRemaining>0 && (danceBlocked || health<danceHealth))
        {
            danceRemaining=0;
            A_StopSound(CHAN_VOICE);
        }
        if (danceDown && !danceHeld && !danceBlocked && danceRemaining==0)
        {
            danceRemaining=52;
            A_StartSound("crash/victory",CHAN_VOICE);
            danceHealth=health;
        }
        danceHeld=danceDown;
        if (danceRemaining>0)
        {
            // Only the short original dance: omit the later gem-reaching clips.
            sprite=GetSpriteIndex('CDN2');
            frame=(52-danceRemaining)/2;
            visualFacing=Angle+180;
            SpriteRotation=180;
            danceRemaining--;
            return;
        }
        if (spinRemaining > 0)
        {
            sprite = GetSpriteIndex('CRSP');
            frame = (14-spinRemaining) % 8;
            if (spinRemaining == 9 || spinRemaining == 4) SpinHit();
            spinRemaining--;
        }
        else if (!bONMOBJ && Pos.Z > FloorZ + 0.5)
        {
            airClock++;
            // Keep the flip running past the apex instead of cutting to falling.
            if (airClock <= 27)
            {
                sprite = GetSpriteIndex('CRJP');
                frame = min(airClock * 17 / 27, 16);
            }
            else
            {
                sprite = GetSpriteIndex('CRFL');
                frame = min((airClock-28) / 3, 5);
            }
        }
        else
        {
            airClock = 0;
            if (Vel.X*Vel.X + Vel.Y*Vel.Y > 0.15)
            {
                sprite = GetSpriteIndex('CRWK');
                frame = (visualClock / 2) % 10;
            }
            else
            {
                sprite = GetSpriteIndex('CRID');
                frame = visualClock % 120 > 115 ? 1 : 0;
            }
        }
    }

    void SpinHit()
    {
        let it = ThinkerIterator.Create('Actor');
        Actor victim;
        while ((victim = Actor(it.Next())) != null)
        {
            if (victim == self || !victim.bSHOOTABLE || victim.health <= 0) continue;
            if (Distance2D(victim) > Radius + victim.Radius + 30) continue;
            if (abs((victim.Pos.Z + victim.Height/2) - (Pos.Z + Height/2)) > 40) continue;
            // Native visibility prevents damage through walls and shut doors.
            if (!CheckSight(victim)) continue;
            bool launch=victim.bISMONSTER && !victim.bBOSS && victim.health<=45;
            if (launch) victim.DeathSound=Sound("");
            victim.DamageMobj(self, self, launch?victim.health:45, 'Melee', DMG_THRUSTLESS);
            if (launch && victim.health<=0)
            {
                double heading=atan2(victim.Pos.Y-Pos.Y,victim.Pos.X-Pos.X);
                victim.Vel=(cos(heading)*18,sin(heading)*18,10);
                victim.A_StopSound(CHAN_VOICE);
                victim.A_StartSound("crash/launch",CHAN_BODY);
            }
        }
    }

    void UpdateVisualFacing()
    {
        if (!facingInitialized) { visualFacing=Angle; facingInitialized=true; }
        Vector2 heading=Vel.XY;
        if (player.cmd.forwardmove || player.cmd.sidemove)
            heading=(cos(Angle)*player.cmd.forwardmove+cos(Angle-90)*player.cmd.sidemove,
                     sin(Angle)*player.cmd.forwardmove+sin(Angle-90)*player.cmd.sidemove);
        if (heading.LengthSquared() > 0.15)
        {
            double destination=atan2(heading.Y,heading.X);
            double difference=(destination-visualFacing+540)%360-180;
            visualFacing+=clamp(difference,-24,24);
        }
        // SpriteRotation also rotates MD3 models, independently of input/camera yaw.
        SpriteRotation=visualFacing-Angle;
    }

    void TryStomp(double oldFeet, bool supported = false)
    {
        let it = ThinkerIterator.Create('Actor');
        Actor victim;
        Actor struck = null;
        double highest = -1e30;
        while ((victim=Actor(it.Next()))!=null)
        {
            if (victim==self || !victim.bSHOOTABLE || victim.health<=0) continue;
            if (!(victim is 'CrashAkuCrate') && !victim.bISMONSTER) continue;
            double top = victim.Pos.Z+victim.Height;
            if ((!supported && oldFeet < top-0.5) || Pos.Z > top+2 || Pos.Z < top-20) continue;
            if (supported && Pos.Z < top-0.5) continue;
            if (Distance2D(victim) > Radius+victim.Radius+1) continue;
            if (!CheckSight(victim)) continue;
            if (top>highest) { highest=top; struck=victim; }
        }
        if (struck)
        {
            struck.DamageMobj(self,self,min(1000,struck.health),'Stomp',DMG_THRUSTLESS);
            if (struck.health<=0)
            {
                stompCount++;
                Vel.Z = (player.cmd.buttons & BT_JUMP) ? 14.5 : 10.5;
                bONMOBJ = false;
                player.onground = false;
                airClock = 0;
            }
        }
    }

    States
    {
    Spawn:
        CRID A -1;
        Loop;
    See:
        CRWK A -1;
        Loop;
    Missile:
    Melee:
        CRID A 1;
        Goto Spawn;
    Pain:
        CRID A 3
        {
            if (hurtCooldown==0)
            {
                A_StartSound("crash/hurt",CHAN_VOICE);
                hurtCooldown=18;
            }
        }
        Goto Spawn;
    VisualDance:
        CDN2 ABCDEFGHIJKLMNOPQRSTUVWXYZ 2;
        CDN3 ABCDEFGHIJKLMNOPQRSTUVWXY 2;
        CDN4 ABCDEFGHIJKLMNOPQRSTUVWXY 2;
        CDN5 ABCDEFGHIJKLMNOPQRSTUVWXY 2;
        CDN6 ABCDEFGHIJKLMNOPQRST 2;
        Stop;
    VisualJump:
        CRJP ABCDEFGHIJKLMNOPQ 1;
        Stop;
    VisualFall:
        CRFL ABCDEF 1;
        Stop;
    VisualSpin:
        CRSP ABCDEFGH 1;
        Stop;
    VisualLand:
        CRLD ABCDE 1;
        Stop;
    Death:
    XDeath:
        CRDT A 3 { A_StartSound("crash/death",CHAN_VOICE); }
        CRDT BCDEFGHIJKLMNOPQRST 3;
        CRDT T -1;
        Stop;
    }
}

class CrashCamera : Actor
{
    bool deathLocked;
    void LockDeathView() { deathLocked=true; }
    Default
    {
        Radius 1;
        Height 1;
        +NOGRAVITY;
        +NOINTERACTION;
        +NOBLOCKMAP;
        RenderStyle "None";
    }
    override void Tick()
    {
        Super.Tick();
        let p = CrashPlayer(Target);
        if (!p || !p.player || p.player.mo != p) { Destroy(); return; }
        if (p.player.camera != self) return;
        if (deathLocked) return;
        let preference = CVar.GetCVar('crash_camera_distance', p.player);
        double distance = preference == null ? 110 : clamp(preference.GetFloat(), 60, 150);
        double elevation = clamp(p.Pitch + 30, -20, 65);
        vector3 focus = p.Pos + (0,0,26);
        vector3 delta = (-cos(p.Angle)*cos(elevation)*distance,
                         -sin(p.Angle)*cos(elevation)*distance,
                         sin(elevation)*distance);
        FLineTraceData hit;
        vector3 position = focus + delta;
        // Trace the camera through native world geometry, including floors and
        // ceilings. Only this invisible camera moves; never the player.
        if (p.LineTrace(p.Angle+180, distance, -elevation,
                        TRF_THRUACTORS|TRF_BLOCKSELF, 26, 0, 0, hit))
            position = hit.HitLocation - delta.Unit()*min(8,hit.Distance);
        SetOrigin(position, false);
        vector3 look = focus-position;
        Angle = atan2(look.Y,look.X);
        Pitch = -atan2(look.Z,look.XY.Length());
    }
    States
    {
    Spawn:
        TNT1 A -1;
        Loop;
    }
}

class CrashWumpaCounter : Inventory
{
    Default
    {
        Inventory.Amount 0;
        Inventory.MaxAmount 999999;
        +INVENTORY.KEEPDEPLETED;
        +INVENTORY.UNDROPPABLE;
    }
}

class CrashWumpa : Inventory
{
    int healAmount;
    int healMax;
    bool megaArmor;
    Default
    {
        Radius 10;
        Height 20;
        Scale 0.75;
        +FLOATBOB;
        +INVENTORY.ALWAYSPICKUP;
        +INVENTORY.NEVERRESPAWN;
        +INVENTORY.QUIET;
        Inventory.PickupSound "crash/wumpa";
    }
    override bool TryPickup(in out Actor toucher)
    {
        if (!toucher.player || toucher.health<=0) return false;
        toucher.GiveInventory('CrashWumpaCounter',1);
        toucher.GiveBody(healAmount>0?healAmount:5,healMax>0?healMax:100);
        if (megaArmor) toucher.GiveInventory('BlueArmor',1);
        toucher.A_StartSound("crash/wumpa",CHAN_ITEM);
        GoAwayAndDie();
        return true;
    }
    States
    {
    Spawn:
        WMFR ABCDEFGHIJKLMN 2;
        Loop;
    }
}

class CrashWumpaWorld : EventHandler
{
    override void WorldThingSpawned(WorldEvent e)
    {
        let a=e.Thing;
        if (!a || (!(a is 'Health') && !(a is 'Soulsphere') && !(a is 'Megasphere'))) return;
        // Preserve native encounter balance while each fruit increments by one.
        int amount=5;
        if (a is 'HealthBonus') amount=1;
        else if (a is 'Stimpack') amount=10;
        else if (a is 'Medikit') amount=25;
        else if (a is 'Soulsphere') amount=100;
        else if (a is 'Megasphere') amount=200;
        let fruit=CrashWumpa(Actor.Spawn('CrashWumpa',a.Pos));
        if (fruit)
        {
            fruit.healAmount=amount;
            fruit.healMax=(a is 'HealthBonus' || a is 'Soulsphere' || a is 'Megasphere')?200:100;
            fruit.megaArmor=a is 'Megasphere';
            fruit.bCOUNTITEM=a.bCOUNTITEM;
            a.Destroy();
        }
    }
    override void RenderOverlay(RenderEvent e)
    {
        let p=players[consoleplayer].mo;
        if (!p || !(p is 'CrashPlayer')) return;
        let counter=p.FindInventory('CrashWumpaCounter');
        int count=counter?counter.Amount:0;
        TextureID icon=TexMan.CheckForTexture("WMPICON",TexMan.Type_Any);
        Screen.DrawTexture(icon,true,14,12,DTA_VirtualWidth,320,DTA_VirtualHeight,200,DTA_DestWidth,24,DTA_DestHeight,24);
        String digits=String.Format("%d",count);
        for (int i=0;i<digits.Length();i++)
        {
            String name=String.Format("WMNUM%s",digits.Mid(i,1));
            TextureID digit=TexMan.CheckForTexture(name,TexMan.Type_Any);
            Screen.DrawTexture(digit,true,42+i*13,15,DTA_VirtualWidth,320,DTA_VirtualHeight,200,DTA_DestWidth,15,DTA_DestHeight,20);
        }
    }
}

class CrashAkuCrate : Actor
{
    Default
    {
        Radius 14;
        Height 30;
        Health 1;
        +SOLID;
        +SHOOTABLE;
        +NOBLOOD;
        +DONTTHRUST;
        +NODAMAGETHRUST;
    }
    States
    {
    Spawn:
        AKBX A -1;
        Loop;
    Death:
        TNT1 A 0 A_NoBlocking;
        TNT1 A 0
        {
            A_StartSound("crash/cratebreak", CHAN_BODY);
            Spawn('CrashAkuPickup', Pos + (0,0,8));
        }
        TNT1 A 8;
        Stop;
    }
}

class CrashAkuPickup : PowerupGiver
{
    Default
    {
        Radius 16;
        Height 28;
        +FLOATBOB;
        +INVENTORY.AUTOACTIVATE;
        +INVENTORY.ALWAYSPICKUP;
        +INVENTORY.NEVERRESPAWN;
        Inventory.PickupMessage "Aku Aku: proteccion durante 20 segundos";
        Inventory.PickupSound "crash/akupickup";
        Powerup.Type "CrashAkuPower";
        Powerup.Duration -20;
    }
    States
    {
    Spawn:
        AKUP A -1;
        Loop;
    }
}

class CrashAkuPower : PowerInvulnerable
{
    CrashAkuOrbit mask;
    Default { Powerup.Duration -20; }
    override void InitEffect()
    {
        BlendColor = 0;
        Super.InitEffect();
        if (Owner)
        {
            mask = CrashAkuOrbit(Spawn('CrashAkuOrbit', Owner.Pos));
            if (mask) mask.Target = Owner;
        }
    }
    override void DoEffect()
    {
        Super.DoEffect();
        if (mask) mask.bINVISIBLE = EffectTics < 105 && (EffectTics % 8 < 4);
    }
    override void EndEffect()
    {
        if (mask) { mask.Destroy(); mask = null; }
        Super.EndEffect();
    }
}

class CrashAkuOrbit : Actor
{
    double phase;
    Default
    {
        Radius 1;
        Height 28;
        +NOGRAVITY;
        +NOINTERACTION;
        +NOBLOCKMAP;
    }
    override void Tick()
    {
        Super.Tick();
        if (!Target || Target.health <= 0 || !Target.FindInventory('CrashAkuPower'))
        { Destroy(); return; }
        phase += 5;
        vector3 focus = Target.Pos + (0,0,24);
        vector3 delta = (cos(phase)*30, sin(phase)*30, sin(phase*2)*2);
        FLineTraceData hit;
        vector3 position = focus + delta;
        // Keep the visual mask inside walls without changing the player's hull.
        if (Target.LineTrace(phase, delta.Length(), -atan2(delta.Z,30),
                             TRF_THRUACTORS|TRF_BLOCKSELF, 24, 0, 0, hit))
            position = hit.HitLocation - delta.Unit()*min(4,hit.Distance);
        SetOrigin(position, false);
        Angle = phase;
    }
    States
    {
    Spawn:
        AKOR A -1;
        Loop;
    }
}

class CrashCratePlacement : EventHandler
{
    bool placed;
    Vector3 positions[4];
    int boxCount;
    override void WorldLoaded(WorldEvent e)
    {
        if (!e.IsSaveGame) { placed = false; boxCount = 0; }
    }
    bool PlaceNear(Actor anchor, double distance)
    {
        for (int a=0; a<360; a+=45)
        {
            double heading = anchor.Angle + a;
            vector3 at = anchor.Pos + (cos(heading)*distance,sin(heading)*distance,0);
            bool spaced = true;
            for (int i=0; i<boxCount; i++)
            {
                Vector3 difference = positions[i]-at;
                if (difference.XY.Length() < 240) spaced = false;
            }
            if (!spaced) continue;
            let box = CrashAkuCrate(Actor.Spawn('CrashAkuCrate', at));
            if (!box) continue;
            box.SetOrigin((at.X,at.Y,box.FloorZ), false);
            if (box.CheckPosition(box.Pos.XY) && box.CeilingZ-box.FloorZ >= 64
                && abs(box.FloorZ-anchor.FloorZ) <= 24 && anchor.CheckSight(box))
            {
                box.Angle = heading;
                positions[boxCount++] = box.Pos;
                return true;
            }
            box.Destroy();
        }
        return false;
    }
    override void WorldTick()
    {
        if (placed || level.time < 2) return;
        Actor p = players[0].mo;
        if (!p) return;
        placed = true;
        PlaceNear(p, 120);
        let it = ThinkerIterator.Create('Inventory');
        Actor item;
        while ((item = Actor(it.Next())) != null && boxCount < 4)
        {
            if (!(item is 'HealthBonus') && !(item is 'ArmorBonus') && !(item is 'Stimpack') && !(item is 'CrashWumpa')) continue;
            if (item.Distance2D(p) < 240) continue;
            PlaceNear(item, 44);
        }
    }
}

