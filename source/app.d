import std.stdio;
import engine;
import niobium;
import inmath;
import numem;
import sdl;

struct VtxData {
	vec2 position;
	vec3 color;
}

void main() {
	initializeEngine();
		Window window = nogc_new!Window("Test", 640, 480);
		NioSurface surface = window.surface;

		// Create buffer for colored triangle.
		NioBuffer vertices = RENDER_DEVICE.createBuffer(NioBufferDescriptor(
			NioBufferUsage.vertexBuffer,
			NioStorageMode.privateStorage,
			VtxData.sizeof*3
		));
		vertices.upload([
			VtxData(vec2(-1, -1), vec3(1, 0, 0)),
			VtxData(vec2(0, 1), vec3(0, 1, 0)),
			VtxData(vec2(1, -1), vec3(0, 0, 1)),
		], 0);

		// Create shader
		NioShader shader = RENDER_DEVICE.createShaderFromNativeSource("triangle.metal", cast(ubyte[])import("triangle.metal"));
		NioRenderPipeline pipeline = RENDER_DEVICE.createRenderPipeline(NioRenderPipelineDescriptor(
			shader.getFunction("vertex_main"),
			shader.getFunction("fragment_main"),
			NioVertexDescriptor(
				[NioVertexBindingDescriptor(NioVertexInputRate.perVertex, VtxData.sizeof)],
				[NioVertexAttributeDescriptor(NioVertexFormat.float2, 0, 0), NioVertexAttributeDescriptor(NioVertexFormat.float3, 0, vec2.sizeof)]
			),
			[NioRenderPipelineAttachmentDescriptor(surface.format, true)],
		));

		// Create command queue.
		NioCommandQueue queue = RENDER_DEVICE.createQueue(NioCommandQueueDescriptor(10));


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

			if (NioDrawable drawable = surface.next()) {
				if (NioCommandBuffer buffer = queue.fetch()) {
					NioRenderCommandEncoder pass = buffer.beginRenderPass(NioRenderPassDescriptor(
						[NioColorAttachmentDescriptor(drawable.texture, 0, 0, 0, NioLoadAction.clear, NioStoreAction.store, NioColor(0, 0, 0, 0))]
					));

					pass.setPipeline(pipeline);
					pass.setVertexBuffer(vertices, 0, 0);
					pass.draw(NioPrimitive.triangles, 0, 3);

					pass.endEncoding();


					buffer.present(drawable);
					queue.commit(buffer);
					buffer.await();
				}
			}
		}
	shutdownEngine();
}
