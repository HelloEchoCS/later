# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

helpers do
  def total_todos(list)
    list[:todos].count
  end

  def undone_todos(list)
    list[:todos].select { |todo| !todo[:completed] }.count
  end

  def list_complete?(list)
    undone_todos(list) == 0 && total_todos(list) > 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todo_class(todo)
    "complete" if todo[:completed]
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }
    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(list, &block)
    complete_todos, incomplete_todos = list[:todos].partition { |todo| todo[:completed] }
    incomplete_todos.each { |todo| yield todo, list[:todos].index(todo) }
    complete_todos.each { |todo| yield todo, list[:todos].index(todo) }
  end
end

get '/' do
  redirect '/lists'
end

get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get '/lists/new' do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if the name is valid.
def error_for_list_name(list_name)
  if !(1..100).include? list_name.length
    'The list name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == list_name }
    'The list name must be unique.'
  end
end

def error_for_todo_entry(todo)
  if !(1..100).include? todo.length
    'The todo entry must be between 1 and 100 characters.'
  end
end

post '/lists' do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

get '/lists/:id/edit' do |id|
  @list = session[:lists][id.to_i]
  erb :edit_list, layout: :layout
end

post '/lists/:id' do
  id = params[:id].to_i
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    session[:lists][id.to_i][:name] = list_name
    session[:success] = 'The change has been saved.'
    redirect "/lists/#{id}"
  end
end

post '/lists/:id/delete' do |id|
  session[:lists].delete_at(id.to_i)
  session[:success] = 'The list has been deleted.'
  redirect "/lists"
end

# Add a new todo to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  todo_text = params[:todo].strip
  @list = session[:lists][@list_id]

  error = error_for_todo_entry(todo_text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    todo = { name: todo_text, completed: false }
    @list[:todos] << todo
    session[:success] = 'The todo has been added.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo entry
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = 'The todo has been deleted.'

  redirect "/lists/#{@list_id}"
end

# Mark a todo entry
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  todo = session[:lists][@list_id][:todos][todo_id]
  is_completed = params[:completed] == "true"
  todo[:completed] = is_completed
  session[:success] = 'The todo has been updated.'

  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete
post '/lists/:id/complete_all' do
  @list_id = params[:list_id].to_i
  todos = session[:lists][@list_id][:todos]
  todos.each do |todo|
    todo[:completed] = true
  end
  session[:success] = 'All todos are completed.'

  redirect "/lists/#{@list_id}"
end