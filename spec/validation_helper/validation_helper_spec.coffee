ValidationHelper = require '../../validation_helper.js'

describe 'Validation Helper', ->
  
  it 'class can be initialised correctly', ->
    helper = new ValidationHelper('/validator')
    expect(helper).not.toBe(null)

  return
