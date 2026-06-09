require "open3"
require "digest"

# Generates a deterministic initials avatar PNG via ImageMagick (magick/convert).
# Replaces the avatarly gem, which is incompatible with Ruby 3.4.
module AvatarGenerator
  PALETTE = %w[#6c8cff #f5a623 #3ecf8e #ff6b6b #a36cff #00b4d8 #ff8fab #2ec4b6 #fa5252 #4dabf7].freeze
  FONTS = [
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
  ].freeze

  module_function

  def png(text, size: 160)
    bg   = PALETTE[Digest::MD5.hexdigest(text.to_s).to_i(16) % PALETTE.size]
    args = [ "-size", "#{size}x#{size}", "xc:#{bg}", "-gravity", "center", "-fill", "white" ]
    # ImageMagick has no default font on many systems — pass one explicitly.
    if (path = font)
      args += [ "-font", path, "-pointsize", (size * 0.42).round.to_s, "-annotate", "+0+0", initials(text) ]
    end
    args << "png:-"

    # Open3.capture3 is called in *array* form (command + separate argv), so no
    # shell is spawned and shell metacharacters in any argument are inert. The
    # only user-derived argument (initials) is also restricted to [A-Z0-9] below.
    %w[magick convert].each do |bin|
      out, _err, status = Open3.capture3(bin, *args)
      return out if status.success?
    rescue Errno::ENOENT
      next
    end
    nil
  end

  def font
    @font = FONTS.find { |f| File.exist?(f) } unless defined?(@font)
    @font
  end

  def initials(text)
    parts = text.to_s.strip.split(/[\s._@-]+/).reject(&:blank?)
    letters = parts.first(2).map { |w| w[0] }.join
    letters = text.to_s.gsub(/[^A-Za-z0-9]/, "")[0, 2] if letters.blank?
    # Strip to [A-Z0-9] so the only user-derived value passed to ImageMagick can
    # never be interpreted as an option/flag (no leading "-", no metacharacters).
    letters.to_s.gsub(/[^A-Za-z0-9]/, "").upcase.presence || "?"
  end
end
