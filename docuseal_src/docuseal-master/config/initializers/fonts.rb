# frozen_string_literal: true

# DocuSeal ships its Unicode (GoNotoKurrent) and signature (DancingScript) fonts
# under vendor/fonts/ so they are available on Heroku's ephemeral filesystem.
#
# On boot in production we expose them through FONT_DIR and register them with
# fontconfig so libvips / HexaPDF can render PDFs with full Unicode support.
font_dir = Rails.root.join('vendor', 'fonts')

ENV['FONT_DIR'] ||= font_dir.to_s

if Rails.env.production? && Dir.exist?(font_dir)
  begin
    user_fonts = File.join(Dir.home, '.fonts')

    FileUtils.mkdir_p(user_fonts)

    Dir.glob(File.join(font_dir, '*.{ttf,otf}')).each do |font|
      FileUtils.cp(font, user_fonts)
    end

    # Make the signature font available to the asset/public path as the original
    # Docker image does (public/fonts/DancingScript-Regular.otf).
    public_fonts = Rails.root.join('public', 'fonts')
    FileUtils.mkdir_p(public_fonts)
    dancing = File.join(font_dir, 'DancingScript-Regular.otf')
    FileUtils.cp(dancing, public_fonts) if File.exist?(dancing)

    system("fc-cache -f #{user_fonts} > /dev/null 2>&1")
  rescue StandardError => e
    Rails.logger.warn("[fonts] Unable to register vendored fonts: #{e.message}")
  end
end
