module game.scrungly;
import game.scrongler;
import game.orb;
import engine;
import game;
import inmath.color;
import std.random;
import std.stdio;

enum SCRUNGLY_OFFSET_RADIUS = 64;

enum SCRUNLGY_TEAM_ZOOM_REF = 100;
enum CAMERA_MIN_ZOOM = 3.5;
enum CAMERA_MAX_ZOOM = 5.0;

/**
    A player controller scrungly.
*/
class Scrungly : Entity {
private:
    __gshared Texture2D texture;
    vec4 color;

    float animSpeed = 0;
    float animTime = 0;
    float rotation = 0;

    float dmgTimer = 0;

    vec2 target = vec2(0, 0);
    vec2 scrunglyOffset;
    Entity targetEntity;

    vec2 getMouseRelativeTarget() {
        vec2i windowSize = GAME_WINDOW.size;
        vec2 mousePos = Mouse.position;
        vec2 viewportSize = vec2(scene.camera.viewport.width, scene.camera.viewport.height);
        mat2 zoomFactInv = mat2.scaling(scene.camera.scale, scene.camera.scale).inverse;

        vec2 mouseUV = vec2((mousePos.x / windowSize.x), (mousePos.y / windowSize.y));
        vec2 mouseRel = (viewportSize*mouseUV)-vec2(viewportSize*0.5);

        return scene.camera.position + (mouseRel * zoomFactInv);
    }

    // Battle
    float attackTimer = 0;
    void updateAttack(float delta) {
        if (targetEntity) {
            if (targetEntity.health <= 0) {
                this.updateOffset();
                this.updateTargetPosition(targetEntity.hitbox.center);
                targetEntity = null;
                return;
            }

            this.updateTargetPosition(targetEntity.hitbox.center);
            attackTimer += delta;

            if (attackTimer >= 1) {
                this.updateOffset();
                targetEntity.damage(10);
                attackTimer = 0;
            }
        }
    }
    
    void updateOffset() {
        this.scrunglyOffset = vec2(
            uniform(-SCRUNGLY_OFFSET_RADIUS, SCRUNGLY_OFFSET_RADIUS), 
            uniform(-SCRUNGLY_OFFSET_RADIUS, SCRUNGLY_OFFSET_RADIUS)
        );
    }

    // Camera Helpers
    __gshared int scrunglyCount = 0;
    void updateCameraZoom() {
        scene.camera.scale = lerp(CAMERA_MAX_ZOOM, CAMERA_MIN_ZOOM, clamp(cast(float)scrunglyCount/cast(float)SCRUNLGY_TEAM_ZOOM_REF, 0, 1));
    }

protected:

    override void onDeath() {
        scrunglyCount--;
        this.updateCameraZoom();
    }

    /**
        Callback invoked when the entity is damaged.

        Params:
            damage = The amount of damage that was taken.
    */
    override void onDamaged(int damage) {
        this.dmgTimer = 1;
    }

public:

    /**
        The hitbox of the entity.
    */
    override @property rect hitbox() => rect(position.x-(texture.width/2), position.y-(texture.height/2), texture.width, texture.height);

    /**
        Constructs a new player.
    */
    this(Scene scene, vec2 spawnPoint) {
        super(scene);

        if (!texture)
            this.texture = nogc_new!Texture2D("assets/sprites/scrungly.png");
        
        this.position = spawnPoint;
        this.target = spawnPoint;
        this.updateOffset();
        this.attackTimer = uniform01();

        // Give each scrungly a random color.
        this.color = vec4(hsv2rgb(vec3(uniform01(), 1, 1)), 1);
        scrunglyCount++;
        this.updateCameraZoom();
    }

    /**
        Updates the entity.

        Params:
            delta = time since last frame.
    */
    override void update(float delta) {

        // Update targeting.
        this.updateAttack(delta);
        
        // Get target direction and velocity.
        vec2 targetDir = (target - position).normalized();
        vec2 velocity = vec2(round(targetDir.x), round(targetDir.y));

        float animSpeedBase = abs(velocity.length());
        if (targetEntity)
            animSpeedBase += 1;

        animSpeed = dampen(animSpeed, animSpeedBase*10*delta, delta);
        position += velocity;

        // Handle damage
        if (dmgTimer > 0) {
            dmgTimer = max(0, dmgTimer-delta);
        }
    }

    /**
        Post-updates the entity.

        Params:
            delta = Time since last frame.
    */
    override void postUpdate(float delta) {
        animTime += animSpeed;

        rotation = lerp(
            0,
            lerp(radians(-10), radians(10), (sin(animTime)+1)/2.0),
            clamp(animSpeed*10, 0, 1)
        );

        if (Mouse.isClicked(MouseButton.BUTTON_LEFT)) {
            vec2 mouseCoords = this.getMouseRelativeTarget();
            this.updateOffset();

            if (auto entity = scene.getEntityAt(mouseCoords)) {
                if (cast(Orb)entity)
                    this.setTarget(entity);
                else if (cast(Scrongler)entity)
                    this.setTarget(entity);
                else
                    this.setTarget(mouseCoords);
            } else {
                this.setTarget(mouseCoords);
            }
        }

        if (targetEntity) {
            if (targetEntity.health < 0)
                targetEntity = null;
        }
    }

    /**
        Draws the entity onto the given sprite batch.

        Params:
            spriteBatch = The sprite batch to render the entity to.
    */
    override void draw(SpriteBatch spriteBatch) {
        spriteBatch.draw(
            texture, 
            rect(drawPosition.x, drawPosition.y, texture.width, texture.height), 
            vec2(0.5, 0.5), 
            rect(0, 0, 1, 1), 
            rotation, 
            lerp(color, vec4(1, 0, 0, 1), dmgTimer)
        );
    }

    /**
        Sets the current target of the scrungly.

        Params:
            position = The position to target for moving.
    */
    void setTarget(vec2 position) {
        this.targetEntity = null;
        this.updateTargetPosition(position);
    }

    /**
        Sets the current target of the scrungly.

        Params:
            entity = The entity to target for attacking.
    */
    void setTarget(Entity entity) {
        this.targetEntity = entity;
    }

    /**
        Updates the target position.
    */
    void updateTargetPosition(vec2 position) {
        target = vec2(
            round(position.x)+scrunglyOffset.x, 
            round(position.y)+scrunglyOffset.y
        );
    
        target.x = clamp(target.x, -BORDER_SIZE, BORDER_SIZE);
        target.y = clamp(target.y, -BORDER_SIZE, BORDER_SIZE);
    }
}