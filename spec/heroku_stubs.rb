# TODO: make a shared context

HEROKU_TIME_FORMAT = '%Y-%m-%dT%H:%M:%S.%6N%:z'
def logplex_url
  'http://cloud.butt'
end

def heroku_double(log_times)
  allow(Net::HTTP).to receive(:get).with(URI(logplex_url)) do
    log_times.map do |log_time|
      log_time.strftime(HEROKU_TIME_FORMAT) + " app[web.1]"
    end.join('\n')
  end

  double(
    'platform_api',
    log_session: double(create: { 'logplex_url' => logplex_url }),
    build: double(create: '')
  )

end
