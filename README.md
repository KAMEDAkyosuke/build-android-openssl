# build-android-openssl

# Usage

```
$ export ANDROID_HOEM=/path/to/your/android/home
$ ./build.sh --api <API_LEVEL>
```

The result will be in the below folders.

* `include` -- openssl headers. copy to your android project.
* `lib`  -- openssl static libraries per architecture. copy to your android project.
* `toolchains` -- ndk toolchains.
* `openssl` -- openssl repo.
