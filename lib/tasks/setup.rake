# frozen_string_literal: true

namespace :docuseal do
  desc 'Download the ONNX model used for automatic PDF field detection'
  task download_model: :environment do
    model_path = Rails.root.join('tmp', 'model.onnx')

    if File.exist?(model_path) && File.size(model_path).positive?
      puts "[docuseal] ONNX model already present at #{model_path}"
      next
    end

    url = ENV.fetch(
      'ONNX_MODEL_URL',
      'https://github.com/docusealco/fields-detection/releases/download/2.0.0/model_704_int8.onnx'
    )

    FileUtils.mkdir_p(model_path.dirname)

    puts "[docuseal] Downloading ONNX model from #{url} ..."
    success = system("curl -fsSL -o #{model_path} #{url}")

    if success && File.exist?(model_path) && File.size(model_path).positive?
      puts "[docuseal] Model downloaded to #{model_path} (#{File.size(model_path)} bytes)"
    else
      # Non-fatal: DocuSeal works without it (manual field placement / HexaPDF fallback).
      FileUtils.rm_f(model_path)
      warn '[docuseal] WARNING: ONNX model download failed. Automatic field detection ' \
           'will be disabled; documents can still be prepared with manual field placement.'
    end
  end
end
