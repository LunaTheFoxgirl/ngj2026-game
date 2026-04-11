import std.stdio;
import engine;
import niobium;
import inmath;
import numem;
import sdl;
import engine.spritebatch;
import engine.input;
import std.random;

struct VtxData {
	vec2 position;
	vec3 color;
}

void main() {
	initializeEngine();
		Window window = nogc_new!Window("Test", 640, 480);
		NioCommandQueue queue = RENDER_DEVICE.createQueue(NioCommandQueueDescriptor(10));
		NioSurface surface = window.surface;
		Texture2D texture = nogc_new!Texture2D("assets/sprites/scrungly.png");
		SpriteBatch batch = nogc_new!SpriteBatch();

		Scrungly[10_000] scrunglies;
		foreach(i; 0..scrunglies.length)
			scrunglies[i] = Scrungly(vec3(uniform01(), uniform01(), uniform01()));


		while(Window.windows.length > 0) {
			SDL_Event ev;
			while(SDL_PollEvent(&ev)) {
				switch (ev.type) {
					case SDL_EventType.SDL_EVENT_WINDOW_CLOSE_REQUESTED:
						window.release();
						break;
					
					default: break;
				}
			}

			import std.random : uniform;
			if (auto drawable = surface.next()) {
				if (auto buffer = queue.fetch()) {
					auto renderPass = buffer.beginRenderPass(NioRenderPassDescriptor([NioColorAttachmentDescriptor(drawable.texture, 0, 0, 0, NioLoadAction.clear, NioStoreAction.store, NioColor(0, 0, 0, 0))]));
						renderPass.setCulling(NioCulling.none);
						NioExtent2D canvasArea = surface.size;
						foreach(ref Scrungly scrungly; scrunglies) {
							batch.draw(texture, rect(scrungly.position.x, scrungly.position.y, texture.width, texture.height), rect(0, 0, 1, 1), scrungly.color);
						}
						batch.flush(renderPass, 
							mat4.orthographic01(0, canvasArea.width, canvasArea.height, 0, 0.1, 1000) * 
							mat4.scaling(10, 10, 1)
						);

					renderPass.endEncoding();
					buffer.present(drawable);
					queue.commit(buffer);
					buffer.await();
				}
			}
		}
	shutdownEngine();
}

struct Scrungly {
	vec4 color;
	vec2 position;

	this(vec3 color) {
		this.color = vec4(color.xyz, 1);
		this.position = vec2(uniform(0, 1000), uniform(0, 1000));
	}
}