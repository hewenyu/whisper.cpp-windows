# whisper.cpp-windows

Auto Build From [whisper.cpp](https://github.com/ggerganov/whisper.cpp)


# Example
Download ZIP File from [Release](https://github.com/hewenyu/whisper.cpp-windows/releases) 

the add env
```bash
$ unzip whisper-bin*.zip && cd whisper-bin*/
$ export PATH=$PATH:$(pwd)
```

## Download model
Download model from [huggingface](https://huggingface.co/ggerganov/whisper.cpp) 

```bash
$ bash model/download-ggml-model.sh base
```

Download samples wav https://github.com/ggerganov/whisper.cpp/raw/master/samples/jfk.wav


You can now use it like this:
```bash
$ ./main -m models/ggml-base.bin -f jfk.wav
```

```bash
bash yt-wsp.sh  https://www.youtube.com/watch?v=DRgPyOXZ-oE
```
