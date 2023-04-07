# whisper.cpp-windows

Auto Build From [whisper.cpp](https://github.com/ggerganov/whisper.cpp)


# Use

Download model from [huggingface](https://huggingface.co/ggerganov/whisper.cpp) 

Download samples wav https://github.com/ggerganov/whisper.cpp/raw/master/samples/jfk.wav

```bash
# linux
./main -m ggml-tiny.en.bin -f  jfk.wav
# win
./main.exe -m ggml-tiny.en.bin -f  jfk.wav
```

