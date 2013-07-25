

//Copyright (c) 2013 William H. Stenico
//background sound Source: http://davidorr.net/Portfolio/?page_id=14
//Other sounds maked in Bfxr


import org.jbox2d.util.nonconvex.*;
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.testbed.*;
import org.jbox2d.collision.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.p5.*;
import org.jbox2d.dynamics.*;



//audio
Maxim maxim;
AudioPlayer explosionSound, pointSound, blipSound, backSound;

Physics physics; // The physics handler: we'll see more of this later

// a handler that will detect collisions
CollisionDetector detector; 

int score, pointLine, timer;

static int ENEMY = 0, SHOT = 1, SPARK = 2;


int holeLength = 100;

PImage tip;

boolean shooting = false, gameOver = false;

Body enemyBody;


void setup() {

  score = 0; 
  timer = 10000;
  gameOver = false;

  size(768, 768);
  frameRate(60);

  //initScene();

  /**
   * Set up a physics world. This takes the following parameters:
   * 
   * parent The PApplet this physics world should use
   * gravX The x component of gravity, in meters/sec^2
   * gravY The y component of gravity, in meters/sec^2
   * screenAABBWidth The world's width, in pixels - should be significantly larger than the area you intend to use
   * screenAABBHeight The world's height, in pixels - should be significantly larger than the area you intend to use
   * borderBoxWidth The containing box's width - should be smaller than the world width, so that no object can escape
   * borderBoxHeight The containing box's height - should be smaller than the world height, so that no object can escape
   * pixelsPerMeter Pixels per physical meter
   */
  physics = new Physics(this, width, height, 0, -2, width*2, height*2, width, height, 100);
  // this overrides the debug render of the physics engine
  // with the method myCustomRenderer
  // comment out to use the debug renderer 
  // (currently broken in JS)
  physics.setCustomRenderingMethod(this, "myCustomRenderer");

  pointLine =  height/2 +150;

  //static objects
  physics.setDensity(0.0f);

  physics.createRect(0, pointLine - 10, width/2 - holeLength/2, pointLine + 10);
  physics.createRect(width/2 + holeLength/2, height/2 - 10+150, width, height/2 + 10+150);
  fill(255);
  physics.setDensity(10.0);

  // sets up the collision callbacks
  detector = new CollisionDetector (physics, this);


  //audio
  maxim = new Maxim(this);

  explosionSound = maxim.loadFile("explosion.wav");  
  explosionSound.setLooping(false);
  explosionSound.volume(1.0);

  pointSound = maxim.loadFile("point.wav");  
  pointSound.setLooping(false);
  pointSound.volume(1.0);

  blipSound = maxim.loadFile("blip.wav");  
  blipSound.setLooping(false);
  blipSound.volume(1.0);

  backSound = maxim.loadFile("ST Pursuit.wav");  
  backSound.setLooping(true);
  backSound.volume(1);
  backSound.play();
}

void draw() {

  background(0);
  timer--;

  if (timer%100==0) {
    pointSound.cue(0);
    backSound.speed(map(timer, 10000, 0, 0.5, 1));
    backSound.play();
  }

  //GAMEOVER BLOCK
  if (timer<=0) { 
    gameOver = true;
    backSound.stop();   
    if (timer%50 == 0) enemyBody = createEnemy();
    explosionSound.play();
    textSize(32);
    fill(255, 0, 0);
    text("GAME OVER!! =) : " + score, 90, height/2);    
    return;
  }


  if (timer%200 == 0) {
    enemyBody = createEnemy();
  }

  if (shooting) Shoot();  

  textSize(32);
  fill(255);
  text("Score: " + score, 10, 30);
  text("Timer: " + timer/10, width-200, 30);
}

void mouseReleased()
{
  shooting = false;
}

void mousePressed() {
  shooting = true;  

  if (gameOver && timer<-500) exit(); //Got time to see the gameOver screen
}

// this function renders the physics scene.
// this can either be called automatically from the physics
// engine if we enable it as a custom renderer or 
// we can call it from draw
void myCustomRenderer(World world) {  

  // iterate through the bodies
  Body body;
  for (body = world.getBodyList(); body != null; body = body.getNext()) {
    // iterate through the shapes of the body    

    org.jbox2d.collision.Shape shape;
    for (shape = body.getShapeList(); shape != null; shape = shape.getNext()) {

      if (body.getMass() >0) {
        strokeWeight(random(0, 10));
        stroke(random(0, 255), random(0, 255), random(0, 255), random(0, 255));                

        UserData data = (UserData) body.getUserData();
        if ((data !=null) && !(data.alive)) {
          if (data.bodyType == ENEMY) {
            int R = (int) map(data.lifeRemaining, 150, 300, 255, 0);
            int G = (int) map(data.lifeRemaining, 0, 150, 0, 255);

            fill(color( R, G, 0));
          }
          else {
            fill(data.c);
          }
        }
        else {
          fill(0);
        }
      }
      else { //static objects
        strokeWeight(0);
        stroke(0);        
        fill(255);
      }

      // find out the shape type
      ShapeType st = shape.getType();
      if (st == ShapeType.POLYGON_SHAPE) {

        // polygon? let's iterate through its vertices while using begin/endShape()
        beginShape();
        PolygonShape poly = (PolygonShape) shape;        
        int count = poly.getVertexCount();
        Vec2[] verts = poly.getVertices();
        for (int i = 0; i < count; i++) {
          Vec2 vert = physics.worldToScreen(body.getWorldPoint(verts[i]));
          vertex(vert.x, vert.y);
        }
        Vec2 firstVert = physics.worldToScreen(body.getWorldPoint(verts[0]));
        vertex(firstVert.x, firstVert.y);
        endShape();
        stroke(0);
        strokeWeight(5);
      }
      else if (st == ShapeType.CIRCLE_SHAPE) {

        // circle? let's find its center and radius and draw an ellipse
        CircleShape circle = (CircleShape) shape;
        Vec2 pos = physics.worldToScreen(body.getWorldPoint(circle.getLocalPosition()));
        float radius = physics.worldToScreen(circle.getRadius());
        ellipseMode(CENTER);
        ellipse(pos.x, pos.y, radius*2, radius*2);
        // we'll add one more line to see how it rotates
        line(pos.x, pos.y, pos.x + radius*cos(-body.getAngle()), pos.y + radius*sin(-body.getAngle()));
      }
    }

    //Explosion Block
    UserData data = (UserData) body.getUserData();
    if (data !=null && !data.alive) {

      data.lifeRemaining--;

      //If block is died
      if (data.lifeRemaining <=0 ) {  
        physics.removeBody(body);

        if (data.bWidth > 0) {
          Vec2 v = physics.getCMPosition(body);

          float speedSound = map(v.y, 0, height, 1, 0.2);
          explosionSound.cue(0);
          explosionSound.speed(speedSound);
          explosionSound.play();

          //POINT
          if ((v.y >= pointLine) && (timer>0)) {
            int scorePoint = (int) map(v.y, height-pointLine, height, 500, 250);
            score+=scorePoint;
            timer+=scorePoint;

            speedSound = map(v.y, height-pointLine, height, 1, 0.5);
            pointSound.cue(0);
            pointSound.speed(speedSound);
            pointSound.play();
          }

          int explosionWidth = 20;
          for (int i = 0;i< 20;i++) {
            Body b1;
            if ((i%2 !=0) && (timer/100<25)) { //Add circles when the time is ending
              b1 = physics.createCircle(v.x, v.y, explosionWidth/2);
            }
            else {                            
              b1 = physics.createRect(v.x, v.y, v.x+explosionWidth, v.y+explosionWidth);
            }
            Vec2 impulse = new Vec2();
            Vec2 to = new Vec2();
            to.x = width/2;
            to.y = 0;
            impulse.set(v);            
            impulse = impulse.sub(to);
            impulse = impulse.mul(-1);
            b1.applyImpulse(impulse, to);
            UserData data1 = new UserData();
            data1.alive = false;
            data1.lifeRemaining *=3;
            data1.bodyType = SPARK;
            
            if (v.y >= pointLine) {
              data1.c = color(50, 50, 255);
            }
            else {
              data1.c = color(255, 255, 0);
            }

            b1.setUserData(data1);
          }
        }
      }
    }
  }
}

// This method gets called automatically when 
// there is a collision
void collision(Body b1, Body b2, float impulse)
{


  UserData data1 = (UserData) b1.getUserData(); 
  if (data1 == null) data1 = new UserData();  

  data1.alive = false;
  
  //Can´t "kill the wall" hehe
  if (b1.getMass() > 0) b1.setUserData(data1);

  UserData data2 = (UserData) b2.getUserData(); 
  if (data2 == null) data2 = new UserData();  

  data2.alive = false;

  //Can´t "kill the wall" hehe
  if (b2.getMass() > 0) b2.setUserData(data2);
}



//==================================== CUSTOM METHODS ======================================

void Shoot() {

  if (timer%5 == 0 && enemyBody!=null) {
    int explosionWidth = 5;

    //Body b1 = physics.createRect(mouseX-explosionWidth, mouseY-explosionWidth, mouseX+explosionWidth, mouseY+explosionWidth);
    Body b1 = physics.createCircle(mouseX, mouseY, explosionWidth);

    Vec2 impulse = new Vec2();
    impulse.set(enemyBody.getWorldCenter());
    impulse = impulse.sub(b1.getWorldCenter());
    impulse = impulse.mul(2);
    b1.applyImpulse(impulse, b1.getWorldCenter());

    UserData data1 = new UserData();
    data1.alive = false;
    data1.lifeRemaining *=1.5;
    data1.bodyType = SHOT;
    data1.c = color(100, 100, 255);

    b1.setUserData(data1);    

    float speedSound = map(mouseY, 0, height, 1, 0);
    blipSound.cue(0);
    blipSound.speed(speedSound);
    blipSound.play();
  }
}

Body createEnemy() {

  UserData data = new UserData();  
  data.bWidth = random(20, 175);
  data.bHeight = random(20, 100);
  data.bodyType = ENEMY;
  data.c = color(100, 255, 50);

  float x = random(0, width-data.bWidth);
  float y = 10;

  if (x+data.bWidth>width) data.bWidth = width - x;
  
  Body body;
  if ((timer%2000 == 0)&& (timer/100<25)) {
    body = physics.createCircle(x, y, (data.bWidth > 100 ? data.bHeight : data.bWidth)/2);
  }
  else {
    body = physics.createRect(x, y, x+data.bWidth, y+data.bHeight);
  } 

  body.setUserData(data);
  return body;
}

//Class to add custom properties on the body...
class UserData {
  color c;
  float bHeight = 0;
  float bWidth = 0;
  int lifeRemaining = 300;
  boolean alive = true;
  int bodyType;
}

