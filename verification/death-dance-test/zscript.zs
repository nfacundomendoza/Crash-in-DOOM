version "4.14"
class DeathDanceChecks : EventHandler {
 Vector3 cameraPosition; double cameraAngle; double bodyAngle; double bodyFacing; int previousFrame; bool stable; bool monotonic;
 override void WorldTick() {
  let p=CrashPlayer(players[0].mo); if(!p)return;
  if(level.time==5) {
   Console.Printf("FIX level_start_alive=%d",p.health==100);
   let it=ThinkerIterator.Create('Actor');Actor a;while((a=Actor(it.Next()))!=null)if(a.bISMONSTER)a.Destroy();
  }
  if(level.time==30) Console.Printf("FIX short_dance_active=%d voice=%d",p.danceRemaining>0 && p.sprite==p.GetSpriteIndex('CDN2'),p.IsActorPlayingSound(CHAN_VOICE,Sound("crash/victory")));
  if(level.time==80) Console.Printf("FIX short_dance_finished=%d",p.danceRemaining==0);
  if(level.time==100) {
   let enemy=Actor.Spawn('ZombieMan',p.Pos+(0,150,0));
   p.DamageMobj(enemy,enemy,1000,'Normal');enemy.Destroy();
  }
  if(level.time==102) {cameraPosition=p.player.camera.Pos;cameraAngle=p.player.camera.Angle;bodyAngle=p.Angle;bodyFacing=p.SpriteRotation;previousFrame=p.frame;stable=true;monotonic=true;}
  if(level.time>102 && level.time<168) {
   stable=stable && p.player.camera.Pos==cameraPosition && p.player.camera.Angle==cameraAngle && p.Angle==bodyAngle && p.SpriteRotation==bodyFacing;
   monotonic=monotonic && p.frame>=previousFrame;previousFrame=p.frame;
  }
  if(level.time==165) Console.Printf("FIX death_locked=%d animation_monotonic=%d last_frame=%d no_early_respawn=%d",stable,monotonic,p.frame,p.health<=0);
 }
}