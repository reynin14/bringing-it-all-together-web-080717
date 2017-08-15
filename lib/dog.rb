require 'pry'
class Dog
  attr_accessor :name, :breed, :id

  def initialize(attributes_hash)
    attributes_hash.each do |k, v|
      self.send(("#{k}="), v)
    end
  end

  def self.create(attributes_hash)
    new_dog = Dog.new(attributes_hash)
    new_dog.save
  end

  def self.create_table
    table = <<-SQL
      CREATE TABLE IF NOT EXISTS dog (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      );
    SQL

    DB[:conn].execute(table)
  end

  def self.drop_table
    table = <<-SQL
      DROP TABLE dogs
    SQL

    DB[:conn].execute(table)
  end

  def save
    table = <<-SQL
      INSERT INTO dogs (name, breed) VALUES (?, ?)
    SQL

    DB[:conn].execute(table, self.name, self.breed)

    results = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs;")
    @id = results.flatten.first

    self
  end


  def self.find_by_id(id)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE id = ?
      LIMIT 1
    SQL

    DB[:conn].execute(sql, id).map do |row|
      self.new_from_db(row)
    end.first

  end

  def self.new_from_db(row)
    dog = Dog.new(name: row[1], breed: row[2], id: row[0])
  end

  def self.find_or_create_by(name:, breed:)
    dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = '#{name}' AND breed = '#{breed}'")
    if !dog.empty?
      dog_data = dog[0]
      dog = Dog.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2])
    else
      dog = self.create(name: name, breed: breed)
    end
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM dogs
      WHERE name = ?
      LIMIT 1
    SQL

    DB[:conn].execute(sql,name).map do |row|
      self.new_from_db(row)
    end.first

  end


  def update
    sql = "UPDATE dogs SET name = ?, breed = ?  WHERE id = ?"
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end


end
