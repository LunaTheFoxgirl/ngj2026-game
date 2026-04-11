module game.scene;
import game.entity;
import engine.spritebatch;
import sdl.timer : SDL_GetTicks;

/**
    A collection of tiles and entities that are currently active in the game.
*/
class Scene {
private:
    long lastTime;
    Entity[] entities;

public:

    /**
        Spawns a given entitiy into the world.
    */
    void spawn(Entity entity) {
        entities ~= entity;
    }

    /**
        Updates the scene and all the entities within.
    */
    void update(SpriteBatch spriteBatch) {
        long currentTime = SDL_GetTicks();
        float deltaTime = cast(float)(currentTime-lastTime) * 0.001;

        // Clean up dead entities
        import std.algorithm.mutation : remove;
        foreach_reverse(i; 0..entities.length) {
            if (!entities[i].isAlive)
                entities = entities.remove(i);
        }

        // Update and draw entities.
        foreach(entity; entities) {
            entity.update(deltaTime);
            entity.draw(spriteBatch);
        }
        lastTime = currentTime;
    }
}