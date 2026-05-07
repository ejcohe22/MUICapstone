from inference.models.base import ModelAdapter
from inference.schemas import ImageGenerationRequest, InferenceResponse, OutputType


class DummyModel(ModelAdapter[ImageGenerationRequest, InferenceResponse]):
    """
    Dummy implementation for testing the pipeline.
    Follows the Strategy Pattern.
    """

    def load(self) -> None:
        print("DummyModel: Mock loading completed.")

    def generate(self, request: ImageGenerationRequest) -> InferenceResponse:
        # Simulate generation by returning a placeholder
        print(f"DummyModel: Generating for prompt '{request.prompt}'")
        
        return InferenceResponse(
            type=OutputType.IMAGE,
            payload="R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7",  # 1x1 transparent pixel
            metadata={"model": "dummy", "prompt": request.prompt}
        )
