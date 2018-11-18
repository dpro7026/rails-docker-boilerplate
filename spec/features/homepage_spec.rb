require 'rails_helper'

RSpec.feature "Creating Home Page" do
  scenario do
    visit '/'

    expect(page).to have_content('Home')
    expect(page).to have_link('Sign In')
    expect(page).to have_link('Sign Up')
    expect(page).to have_link('All Posts')
  end
end
