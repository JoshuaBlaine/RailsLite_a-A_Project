require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require_relative './flash'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, params = {})
    @req = req
    @res = res
    @params = params
    @already_built_response = false
    @session = Session.new(req)
    @flash = Flash.new(req)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Can't render twice" if already_built_response?
    res.header["location"] = url
    res.status = 302
    session.store_session(res)
    @already_built_response = true
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Can't render twice" if already_built_response?
    res['Content-Type'] = content_type
    res.write(content)
    session.store_session(res)
    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller = "#{self.class}".underscore
    erb = ERB.new(File.read("views/#{controller}/#{template_name}.html.erb"))
    render_content(erb.result(binding), "text/html")
  end

  # method exposing a `Session` object
  def session
    @session
  end

  def flash
    @flash
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
  end
end
