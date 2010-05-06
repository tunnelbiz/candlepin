require 'spec/expectations'
require 'candlepin_api'

Given /^I have username "(\w+)"$/ do |username|
    # Not using username right now
    @username = username
end

Given /^I have password "(\w+)"$/ do |password|
    # Not using password right now
    @password = password
end

Given /^I am a Consumer "([^\"]*)"$/ do |consumer_name|
  # Just hardcodes in username/password so that
  # all the features don't have to spell it out

  # Currently this lines up with the default user that is defined
  # in common_steps

  @username = 'some_guy'
  @password = 'password'
  When "I Register a New Consumer \"#{consumer_name}\""
end

Given /^I am user "([^\"]*)" with password "([^\"]*)"$/ do |username, password|
  @candlepin.use_credentials(username, password)
end

When /^I become user "([^\"]*)" with password "([^\"]*)"$/ do |username, password|
  @candlepin.use_credentials(username, password)
end

When /I Register a New Consumer "(\w+)"$/ do |consumer_name|
    consumer = {
        :consumer => {
            :type => {:label => :system},
            :name => consumer_name,
        }
    }

    @candlepin.register(consumer, @username, @password)
end

Given /^there is no Consumer with uuid "([^\"]*)"$/ do |uuid|
    @candlepin.use_credentials(@username, @password)
    begin
        @candlepin.unregister(uuid)
    rescue RestClient::Exception => e
        # If it doesn't exist already, then we don't care if the unregister
        # failed
        e.message.should == "Resource Not Found"
        e.http_code.should == 404
    end
end

Given /^Consumer "([^\"]*)" exists with uuid "([^\"]*)"$/ do |consumer_name, uuid|
    # Again - bad!
    @username = 'foo'
    @password = 'password'
    Given "there is no Consumer with uuid \"#{uuid}\""
    When "I Register a New Consumer \"#{consumer_name}\" with uuid \"#{uuid}\""
end

When /I Register a New Consumer "([^\"]*)" with uuid "([^\"]*)"$/ do |consumer_name, uuid|
    consumer = {
        :consumer => {
            :type => {:label => :system},
            :name => consumer_name,
            :uuid => uuid
        }
    }

    @candlepin.register(consumer, @username, @password)
end

Then /^Registering another Consumer with uuid "([^\"]*)" causes a bad request$/ do |uuid|
    consumer = {
        :consumer => {
            :type => {:label => :system},
            :name => "any name",
            :uuid => uuid
        }
    }

    begin
        @candlepin.register(consumer, @username, @password)
    rescue RestClient::Exception => e
        e.message.should == "Bad Request"
        e.http_code.should == 400
    else
        assert(fail, "Excepted exception was not raised")
    end

end

Then /^Searching for a Consumer with uuid "([^\"]*)" causes a not found$/ do |uuid|

    lambda {@candlepin.get_consumer(uuid)}.should raise_error
    begin
        @candlepin.get_consumer(uuid)
    rescue RestClient::Exception => e
        e.message.should == "Resource Not Found"
        e.http_code.should == 404
    end

end

When /I Revoke All My Entitlements/ do
    @candlepin.revoke_all_entitlements
end

Then /The (\w+) on my Identity Certificate's Subject is My ([\w ]+)'s (\w+)/ do |subject_property, entity, property|
    expected = @candlepin.send(to_name(entity))[ to_name(property) ]
    subject_value(subject_property).should == expected
end

Then /The (\w+) on my Identity Certificate's Subject is (\w+)$/ do |subject_property, expected|
    subject_value(subject_property).should == expected
end

# Grabs the value of a key=value pair in the identity cert's subject
def subject_value(key)
    subject = @candlepin.identity_certificate.subject
    subject.to_s.scan(/\/#{key}=([^\/=]+)/)[0][0]
end 
