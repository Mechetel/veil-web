# Idempotent seed users. Run: bin/rails db:seed
[
  { email_address: "admin@veil.local", password: "password", role: :admin },
  { email_address: "user@veil.local",  password: "password", role: :simple }
].each do |attrs|
  user = User.find_or_initialize_by(email_address: attrs[:email_address])
  next unless user.new_record?

  user.update!(password: attrs[:password], password_confirmation: attrs[:password], role: attrs[:role])
  puts "Seeded #{attrs[:role]}: #{attrs[:email_address]} / #{attrs[:password]}"
end
