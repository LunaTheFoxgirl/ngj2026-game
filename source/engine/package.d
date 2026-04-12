/**
    Root engine module.

    Authors:
        Luna Nielsen
*/
module engine;
import sdl.timer;
import sdl;

public import engine.window;
public import engine.texture;
public import engine.spritebatch;
public import niobium;
public import numem;
public import inmath;
public import engine.input;

/**
    The global rendering device used to render throughout the lifetime of the game.
*/
__gshared NioDevice RENDER_DEVICE;

/**
    The main render command queue.
*/
__gshared NioCommandQueue RENDER_QUEUE;

/**
    The main render sprite batch.
*/
__gshared SpriteBatch RENDER_BATCH;

/**
    The main game window.
*/
__gshared Window GAME_WINDOW;

/**
    Game render surface.
*/
__gshared NioSurface GAME_SURFACE;

/**
    Initializes the engine.
*/
void initializeEngine() @nogc{
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD | SDL_INIT_HAPTIC);
    RENDER_DEVICE = NioDevice.systemDevices[0];
	RENDER_QUEUE = RENDER_DEVICE.createQueue(NioCommandQueueDescriptor(10));
    RENDER_BATCH = nogc_new!SpriteBatch();
    GAME_WINDOW = nogc_new!Window("Scrungly's Void Stroll", 1920, 1080);
    GAME_SURFACE = GAME_WINDOW.surface;
}

/**
    Updates core engine systems.
*/
void updateEngineCore() @nogc {
    SDL_Event ev;
    while(SDL_PollEvent(&ev)) {
        switch (ev.type) {
            case SDL_EventType.SDL_EVENT_WINDOW_CLOSE_REQUESTED:
                foreach(window; Window.windows)
                    window.release();
                break;
            
            default: break;
        }
    }

    Keyboard.update();
    Mouse.update();
}

/**
    Shuts down the engine.
*/
void shutdownEngine() @nogc {
    GAME_WINDOW.release();
    nogc_delete(RENDER_BATCH);
    RENDER_QUEUE.release();
    RENDER_DEVICE.release();
}

/**
    Gets the time in ticks.
*/
long getTimeTicks() {
    return SDL_GetTicks();
}