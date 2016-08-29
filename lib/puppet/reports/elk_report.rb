require 'puppet'
require 'elasticsearch'

Puppet::Reports.register_report(:elk_report) do
  desc "Send reports to ELK stack"

  def process
    client = Elasticsearch::Client.new host: 'localhost'
    index_date = Time.now.utc.to_date
    messages = Array.new

    self.resource_statuses.each do |k,v|
      puts v.resource_type
      puts v.title
      v.events.each do |e|
        puts e.name
      end
    end

    #Notice: /Stage[main]/Main/File[/tmp/foo]/ensure: created
    list=self.logs
    list.each_with_index do |l,i|
      message = "#{l.level.capitalize}: "
      message << "#{l.source}: " if l.source and l.source != 'Puppet'
      message << l.message
      messages << message
    end

    client.create index: "puppet-#{index_date}",
      type: 'log',
      body: {
       puppet_configuration_version: "config version #{self.configuration_version}",
       puppet_environment: self.environment,
       puppet_message: messages,
       puppet_version: "#{self.puppet_version}",
       puppet_status: self.status,
       puppet_host: self.host,
       puppet_time: self.time,
       puppet_type: self.kind,
       tags: ['puppet', 'puppet_log'],
       published: true,
       published_at: Time.now.utc.iso8601,
      }
  end
end
