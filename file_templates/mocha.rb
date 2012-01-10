require 'mocha'

World(Mocha::API)
 
Before do
  mocha_setup
  # Paperclip::Attachment.any_instance.stubs(:post_process).returns(true)
  # Paperclip::Storage::S3.stubs(:to_file).returns(true)
  # AWS::S3::S3Object.stubs(:exists?).returns(true)
#  User.any_instance.stubs(:destroy_attached_files).returns(true)
#  User.any_instance.stubs(:save_attached_files).returns(true)
end
 
After do
  begin
    mocha_verify
  ensure
    mocha_teardown
  end
end

