---
name: Library/maciejszulia/Local AI
tags: meta/library
---
Configuration of the silverbullet-ai plug for a local Ollama server with qwen3.5 models. Requires the silverbullet-ai plug 0.9.3, installed separately; this page only configures it.

```space-lua
-- boot: true
config.set {
  ai = {
    providers = {
      ollama = {
        baseUrl = "http://localhost:11434/v1",
        useProxy = false,
        preferredModels = {"qwen3.5:4b", "qwen3.5:2b", "qwen3.5:0.8b"},
        timeout = 1800
      }
    },
    defaultTextModel = "ollama:qwen3.5:4b",
    chat = {
      userInstructions = "Odpowiadaj po polsku, poprawną polszczyzną i krótko."
    }
  }
}
```
