require 'rails_helper'

feature "Index Page", type: :feature do
  context "HTML format" do
    context "INDEX_REDIRECT_URL is blank" do
      before do
        ENV['INDEX_REDIRECT_URL'] = nil
      end

      it "returns the application information" do
        visit '/index'
        json = JSON.parse(page.body)
        expect(json).to have_key('expense')
      end
    end

    context "INDEX_REDIRECT_URL presents" do
      before do
        ENV['INDEX_REDIRECT_URL'] = '/users/sessions/current_user'
      end

      it "redirects to INDEX_REDIRECT_URL" do
        visit '/index'
        expect(page.current_url).to match(%r{/users/sessions/current_user})
      end
    end
  end

  context "JSON format" do
    it "returns the application information" do
      visit '/index.json'
      json = JSON.parse(page.body)
      expect(json).to have_key('expense')
    end
  end
end
