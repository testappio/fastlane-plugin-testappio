describe Fastlane::Actions::UploadToTestappioAction do
  describe '#run' do
    it 'upload the apk and ipa files' do
      expect do
        Fastlane::FastFile.new.parse("lane :test do
          # upload both Android (apk) & iOS (ipa)
          upload_to_testappio(
            api_token: '',
            app_id: '',
            release: 'both',
            apk_file: './fastlane/sample/sample-app.apk',
            ipa_file: './fastlane/sample/sample-app.ipa',
            release_notes: 'Manual release notes',
            git_release_notes: true,
            git_commit_id: false,
            notify: false,
            self_update: true
          )
        end").runner.execute(:test)
      end.to raise_error(anything)
    end
  end
end
