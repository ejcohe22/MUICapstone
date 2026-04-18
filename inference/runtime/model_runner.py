class ModelRunner:
    def __init__(self, model):
        self.model = model

    def load(self):
        self.model.load()

    def generate(self, req):
        return self.model.generate(req.model_dump())
