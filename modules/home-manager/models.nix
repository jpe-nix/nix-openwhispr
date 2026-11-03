# Links the pinned models package into the cache layout the upstream application
# reads. The file list mirrors the output layout of pkgs/openwhispr-models.
{ config, lib, ... }:
let
  cfg = config.programs.openwhispr;
  modelFiles = [
    "diarization-models/3dspeaker_speech_campplus_sv_en_voxceleb_16k.onnx"
    "diarization-models/sherpa-onnx-pyannote-segmentation-3-0/model.onnx"
    "diarization-models/silero_vad.onnx"
    "embedding-models/all-MiniLM-L6-v2/model.onnx"
    "embedding-models/all-MiniLM-L6-v2/tokenizer.json"
    "whisper-models/ggml-base.bin"
  ];
in
{
  config = lib.mkIf (cfg.enable && cfg.models.bootstrap) {
    home.file = lib.listToAttrs (
      map (
        relPath:
        lib.nameValuePair ".cache/openwhispr/${relPath}" {
          source = "${cfg.models.package}/${relPath}";
          force = true;
        }
      ) modelFiles
    );
  };
}
