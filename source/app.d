import std.stdio;
import engine;
import niobium;
import inmath;
import numem;
import sdl;
import engine.spritebatch;
import engine.input;

struct VtxData {
	vec2 position;
	vec3 color;
}

void main() {
	initializeEngine();
		Window window = nogc_new!Window("Test", 640, 480);
		NioCommandQueue queue = RENDER_DEVICE.createQueue(NioCommandQueueDescriptor(10));
		NioSurface surface = window.surface;
		Texture2D texture = nogc_new!Texture2D("assets/fox.png");
		SpriteBatch batch = nogc_new!SpriteBatch();


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
						foreach(i; 0..100_000) {
							batch.draw(texture, rect(uniform(0, canvasArea.width), uniform(0, canvasArea.height), texture.width/2, texture.height/2), vec2(0.5, 0.5));
						}
						batch.flush(renderPass, 
							mat4.orthographic01(0, canvasArea.width, canvasArea.height, 0, 0.1, 1000)
						);

					renderPass.endEncoding();
					buffer.present(drawable);
					queue.commit(buffer);
				}
			}
		}
	shutdownEngine();
}
