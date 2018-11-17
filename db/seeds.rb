if Rails.env.development?
    User.create!(first_name: 'Harry', last_name: 'Potter', email: 'harrypotter@example.com', password: 'password1', password_confirmation: 'password1')
end
