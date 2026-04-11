module engine.window;
import sdl.metal;
import niobium;
import nulib;
import numem;
import inmath;
import sdl;
import engine;
import std.stdio : writeln;

/**
    The window which the game operates within.
*/
class Window : NuRefCounted {
private:
@nogc:
    SDL_Window* handle;
    NioSurface surface_;

    //
    //              APP-GLOBAL DATA
    //
    __gshared vector!Window windows_;



    //
    //              SDL HELPERS
    //
    vec2i getSizePt() {
        vec2i result;
        SDL_GetWindowSize(handle, &result.vector[0], &result.vector[1]);
        return result;
    }

    vec2i getSizePx() {
        vec2i result;
        SDL_GetWindowSizeInPixels(handle, &result.vector[0], &result.vector[1]);
        return result;
    }

    vec2i getPos() {
        vec2i result;
        SDL_GetWindowPosition(handle, &result.vector[0], &result.vector[1]);
        return result;
    }

    NioSurface createSurface() {
        version(OSX) {
            
            auto view = SDL_Metal_CreateView(handle);
            auto surface = NioSurface.createForLayer(SDL_Metal_GetLayer(view));
            surface.device = RENDER_DEVICE;
            surface.size = NioExtent2D(640, 480);
            surface.format = NioPixelFormat.bgra8UnormSRGB;
            surface.framesInFlight = 3;
            surface.presentMode = NioPresentMode.mailbox;
            return surface;
        } else version(linux) {

        }
    }

public:

    /**
        List of all currently open windows.
    */
    static @property Window[] windows() => windows_.value;

    /**
        The title of the window
    */
    @property string title() => cast(string)SDL_GetWindowTitle(handle).fromStringz;
    @property void title(string value) {
        SDL_SetWindowTitle(handle, value.ptr);
    }

    /**
        Position of the window
    */
    @property vec2i position() => this.getPos();
    @property void position(vec2i value) {
        SDL_SetWindowPosition(handle, value.x, value.y);
    }

    /**
        The size of the window in window units (aka points).
    */
    @property vec2i size() => this.getSizePt();

    /**
        The size of the window in pixels.
    */
    @property vec2i sizePx() => this.getSizePx();

    /**
        The rendering surface belonging to the window.
    */
    @property NioSurface surface () => surface_;

    /// Destructor
    ~this() {
        windows_.remove(this);
        SDL_DestroyWindow(handle);
    }

    /**
        Constructs a new GameWindow with a title, width and height.

        Params:
            title =     The title of the window.
            width =     The width of the window.
            height =    The height of the window
    */
    this(string title, uint width, uint height) {
        enum windowFlags = SDL_WindowFlags.SDL_WINDOW_RESIZABLE | SDL_WindowFlags.SDL_WINDOW_HIGH_PIXEL_DENSITY;
        this.handle = SDL_CreateWindow(title.ptr, width, height, cast(SDL_WindowFlags)windowFlags);
        this.surface_ = this.createSurface();
        this.windows_ ~= this;
    }
}