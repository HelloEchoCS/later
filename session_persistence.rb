class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def all_list
    @session[:lists]
  end

  def find_list(id)
    @session[:lists].find { |list| list[:id] == id }
  end

  def add_list(list_name)
    id = get_list_id(all_list)
    @session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    @session[:lists].reject! { |list| list[:id] == id.to_i }
  end

  def update_list_name(id, list_name)
    find_list(id)[:name] = list_name
  end

  def add_new_todo(list_id, todo_text)
    list = find_list(list_id)
    id = get_todo_id(list[:todos])
    todo = { id: id, name: todo_text, completed: false }
    list[:todos] << todo
  end

  def delete_todo_from_list(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].delete_if { |todo| todo[:id] == todo_id }
  end

  def mark_todo_status(list_id, todo_id, status)
    list = find_list(list_id)
    todo = list[:todos].find { |todo| todo[:id] == todo_id }
    todo[:completed] = status
  end

  def complete_all_todos(list_id)
    list = find_list(list_id)
    list[:todos].each { |todo| todo[:completed] = true }
  end

  private

  def get_list_id(lists)
    max = lists.map { |list| list[:id] }.max || 0
    max + 1
  end

  def get_todo_id(todos)
    max = todos.map { |todo| todo[:id] }.max || 0
    max + 1
  end

end