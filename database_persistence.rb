require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: 'todos')
          end
    @logger = logger
    # @session = session
    # @session[:lists] ||= []
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_list
    # @session[:lists]
    sql = 'SELECT * FROM lists;'
    result = query(sql)
    result.map do |tuple|
      todo_items = retrieve_todo_items(tuple)
      { id: tuple['id'].to_i, name: tuple['name'], todos: todo_items }
    end
  end

  def find_list(id)
    sql = 'SELECT * FROM lists WHERE id = $1;'
    result = query(sql, id)

    tuple = result.first
    todo_items = retrieve_todo_items(tuple)
    { id: tuple['id'].to_i, name: tuple['name'], todos: todo_items }
    # @session[:lists].find { |list| list[:id] == id }
  end

  def add_list(list_name)
    # id = get_list_id(all_list)
    sql = 'INSERT INTO lists (name) VALUES ($1);'
    query(sql, list_name)
    # @session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    sql = 'DELETE FROM lists WHERE id = $1;'
    query(sql, id)
    # @session[:lists].reject! { |list| list[:id] == id.to_i }
  end

  def update_list_name(id, list_name)
    # find_list(id)[:name] = list_name
    sql = 'UPDATE lists SET name = $1 WHERE id = $2;'
    query(sql, list_name, id)
  end

  def add_new_todo(list_id, todo_text)
    # list = find_list(list_id)
    # id = get_todo_id(list[:todos])
    # todo = { id: id, name: todo_text, completed: false }
    # list[:todos] << todo
    sql = 'INSERT INTO items (name, list_id) VALUES ($1, $2);'
    query(sql, todo_text, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    # list = find_list(list_id)
    # list[:todos].delete_if { |todo| todo[:id] == todo_id }
    sql = 'DELETE FROM items WHERE list_id = $1 AND id = $2;'
    query(sql, list_id, todo_id)
  end

  def mark_todo_status(list_id, todo_id, status)
    # list = find_list(list_id)
    # todo = list[:todos].find { |todo| todo[:id] == todo_id }
    # todo[:completed] = status
    sql = 'UPDATE items SET completed = $1 WHERE list_id = $2 AND id = $3;'
    query(sql, status, list_id, todo_id)
  end

  def complete_all_todos(list_id)
    # list = find_list(list_id)
    # list[:todos].each { |todo| todo[:completed] = true }
    sql = "UPDATE items SET completed = 'true' WHERE list_id = $1;"
    query(sql, list_id)
  end

  private

  def retrieve_todo_items(record)
    id = record['id']
    sql = 'SELECT * FROM items WHERE list_id = $1;'
    result = query(sql, id)
    result.map do |tuple|
      { id: tuple['id'].to_i,
        name: tuple['name'],
        completed: tuple['completed'] == 't' }
    end
  end

  # def get_list_id(lists)
  #   max = lists.map { |list| list[:id] }.max || 0
  #   max + 1
  # end

  # def get_todo_id(todos)
  #   max = todos.map { |todo| todo[:id] }.max || 0
  #   max + 1
  # end

end