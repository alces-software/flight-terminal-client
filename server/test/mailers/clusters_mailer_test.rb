require 'test_helper'

class ClustersMailerTest < ActionMailer::TestCase
  test "launched" do
    launch_config = ClusterLaunchConfig.new(
      email: 'me@example.com',
      name: 'my-cluster',
    )
    output = File.read(Rails.root.join('test/mailers/previews/output.sample'))

    mail = ClustersMailer.launched(launch_config, output)
    assert_equal "Launched cluster #{launch_config.name}", mail.subject
    assert_equal [launch_config.email], mail.to
    assert_equal ["launch@alces-flight.com"], mail.from

    # assert_equal read_fixture('launched').join, mail.body.to_s
    assert_match read_fixture('launched').join, mail.body.to_s
  end

  test "failed" do
    launch_config = ClusterLaunchConfig.new(
      email: 'me@example.com',
      name: 'my-cluster',
    )
    output = File.read(Rails.root.join('test/mailers/previews/failed.deleted-whilst-creating.sample'))
    arn = 'arn:aws:cloudformation:us-east-1:700366075446:stack/flight-cluster-bens-test-2/a4c95470-099e-11e7-8ce5-500c217b4a9a'

    mail = ClustersMailer.failed(launch_config, output, arn)
    assert_equal "Failed to launch cluster #{launch_config.name}", mail.subject
    assert_equal [launch_config.email], mail.to
    assert_equal ["launch@alces-flight.com"], mail.from

    # assert_equal read_fixture('failed').join, mail.body.to_s
    assert_match read_fixture('failed').join, mail.body.to_s
  end
end
