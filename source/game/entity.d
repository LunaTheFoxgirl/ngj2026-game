module game.entity;
import engine;
import game.scene;

/**
    An entity within the game.
*/
abstract class Entity {
private:
    Scene scene_;
    int health_ = 100;

protected:

    /**
        Position of the entity, in pixels.
    */
    vec2 position = vec2(0, 0);

    /**
        Base constructor of entities.

        Params:
            scene = The owning scene.
    */
    this(Scene scene) {
        this.scene_ = scene;
    }

    /**
        Callback invoked when the entity dies.
    */
    void onDeath() { }
    
public:

    /**
        Scene this entity belongs to.
    */
    final @property Scene scene() => scene_;

    /**
        The position that the entity is to be drawn at.
    */
    final @property vec2 drawPosition() => vec2(round(position.x), round(position.y));

    /**
        Whether the entity is alive.
    */
    final @property bool isAlive() => health_ > 0;

    /**
        Health of the entity.
    */
    final @property int health() => health_;

    /**
        Updates the entity.

        Params:
            delta = Time since last frame.
    */
    abstract void update(float delta);

    /**
        Post-updates the entity.

        Params:
            delta = Time since last frame.
    */
    abstract void postUpdate(float delta);

    /**
        Draws the entity onto the given sprite batch.

        Params:
            spriteBatch = The sprite batch to render the entity to.
    */
    abstract void draw(SpriteBatch spriteBatch);

    /**
        Moves the entity to a given coordinate.

        Params:
            to = The position to move the entity to.
    */
    final void move(vec2 to) {
        this.position = to;
    }

    /**
        Damages the entity.

        Params:
            attack = the attack power of the entity.
    */
    final void damage(int attack) {
        this.health_ -= attack;
        if (health_ <= 0)
            this.onDeath();
    }
}