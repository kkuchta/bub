# Stores who's claimed what between requests.  It uses file storage, which means:
#   - The claims will by wiped by heroku on deploy and/or restart
#   - Concurrent access might not do what you expect (unless I add a bunch of
#     code that wouldn't be worth it)
# So, TODO: replace this with a db or a key-value store or something.
class Claims
  STORAGE_FILENAME = '/tmp/bub_claims'

  # Claim this app, overwriting any previous claim
  def take(app, user, expires_at)
    claims_data[app] = {
      user: user,
      expires_at: expires_at
    }
    save
  end

  # { user: kevin, expires_at: "2016-02-01 10:10:10 -800" }
  def info(app)
    claims_data[app]
  end

  private

  def claims_data
    @claims_data || load_saved
  end

  def load_saved
    @claims_data = if File.exist?(STORAGE_FILENAME)
      data = File.read(STORAGE_FILENAME)
      claims_hash = JSON.parse(data)
      claims_hash.each do |app, app_data|
        app_data = app_data.symbolize_keys
        app_data[:expires_at] = DateTime.parse(app_data[:expires_at] || Time.now.to_s)
        claims_hash[app] = app_data
      end
    else
      {}
    end
  end

  def save
    File.write(STORAGE_FILENAME, claims_data.to_json)
  end
end
