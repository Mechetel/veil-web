# The shared, read-only collection of default images available to every user.
# Drop PNG/JPG files into public/default_images/ — they are listed in the
# image pickers ("Defaults" mode) and copied into the user's gallery when used.
module DefaultImages
  module_function

  def dir
    Rails.public_path.join("default_images")
  end

  def all
    Dir.glob(dir.join("*.{png,jpg,jpeg}")).map { |p| File.basename(p) }.sort
  end

  # Whitelist lookup (no path traversal): returns the absolute path or nil.
  def path_for(name)
    all.include?(name.to_s) ? dir.join(name.to_s) : nil
  end

  def content_type_for(name)
    name.to_s.downcase.end_with?(".png") ? "image/png" : "image/jpeg"
  end
end
