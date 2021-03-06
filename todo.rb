# frozen_string_literal: true

require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'

require_relative 'database_persistence'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_persistence.rb'
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
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
    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(list, &block)
    complete_todos, incomplete_todos = list[:todos].partition { |todo| todo[:completed] }
    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

get '/' do
  redirect '/lists'
end

get '/lists' do
  @lists = @storage.all_list
  erb :lists, layout: :layout
end

get '/lists/new' do
  # @lists = @storage.all_list
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if the name is valid.
def error_for_list_name(list_name)
  if !(1..100).include? list_name.length
    'The list name must be between 1 and 100 characters.'
  elsif @storage.all_list.any? { |list| list[:name] == list_name }
    'The list name must be unique.'
  end
end

def error_for_todo_entry(todo)
  if !(1..100).include? todo.length
    'The todo entry must be between 1 and 100 characters.'
  end
end

def find_list(id)
  @storage.find_list(id)
end

def load_list(id)
  id = id.to_i
  list = find_list(id) # if id && find_list(id)
  return list if list

  session[:error] = 'The specific list was not found.'
  redirect '/lists'
end

post '/lists' do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @storage.add_list(list_name)
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

get '/lists/:id' do
  # @list_id = params[:id].to_i
  # if @lists.none? { |list| list[:id] == @list_id }
  #   session[:error] = 'The specific list was not found.'
  #   redirect '/lists'
  # end
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :list, layout: :layout
end

# Render the Edit List page
get '/lists/:id/edit' do |id|
  @list = load_list(id)
  erb :edit_list, layout: :layout
end

# Submit the change to the list
post '/lists/:id' do
  id = params[:id].to_i
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(id, list_name)
    session[:success] = 'The change has been saved.'
    redirect "/lists/#{id}"
  end
end

# Delete a list
post '/lists/:id/delete' do |id|
  @storage.delete_list(id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = 'The list has been deleted.'
    redirect "/lists"
  end
end

# Add a new todo to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  todo_text = params[:todo].strip
  @list = load_list(@list_id)

  error = error_for_todo_entry(todo_text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else

    @storage.add_new_todo(@list_id, todo_text)

    session[:success] = 'The todo has been added.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo entry
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i

  @storage.delete_todo_from_list(@list_id, todo_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = 'The todo has been deleted.'
    redirect "/lists/#{@list_id}"
  end
end

# Mark a todo entry
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"

  @storage.mark_todo_status(@list_id, todo_id, is_completed)

  session[:success] = 'The todo has been updated.'

  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete
post '/lists/:id/complete_all' do
  @list_id = params[:id].to_i

  @storage.complete_all_todos(@list_id)

  session[:success] = 'All todos are completed.'

  redirect "/lists/#{@list_id}"
end
