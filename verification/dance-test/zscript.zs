version "4.14"
class DanceChecks : EventHandler {
 override void WorldTick() {
  let p=CrashPlayer(players[0].mo); if(!p)return;
  if(level.time==5) {let it=ThinkerIterator.Create('Actor');Actor a;while((a=Actor(it.Next()))!=null)if(a.bISMONSTER)a.Destroy();}
  if(level.time==100) Console.Printf("DANCE started=%d facing=%d",p.danceRemaining>0,p.SpriteRotation==180);
  if(level.time==330) Console.Printf("DANCE completed=%d",p.danceRemaining==0);
  if(level.time==370) Console.Printf("DANCE movement_cancel=%d",p.danceRemaining==0);
  if(level.time==425) {Console.Printf("DANCE restarted=%d",p.danceRemaining>0);p.DamageMobj(null,null,1,'Normal');}
  if(level.time==430) Console.Printf("DANCE hurt_cancel=%d",p.danceRemaining==0);
 }
}