import React from 'react';
import { componentTypes, validatorTypes } from '@@ddf';


function fieldsForAIX(state, setState, storages, buckets)
{
  return [
    {
      component: componentTypes.TEXT_FIELD,
      name: 'aix_net_loc',
      id: 'aix_net_loc',
      label: __('AIX Network Location'),
      isRequired: true,
      validate: [{ type: validatorTypes.REQUIRED }],
      clearOnUnmount: true,
    },

    {
      component: componentTypes.TEXT_FIELD,
      name: 'ssh_user',
      id: 'ssh_user',
      label: __('SSH Username'),
      isRequired: true,
      validate: [{ type: validatorTypes.REQUIRED }],
      clearOnUnmount: true,
    },

    {
      component: componentTypes.TEXT_FIELD,
      type: 'password',
      name: 'ssh_pass',
      id: 'ssh_pass',
      label: __('SSH Password'),
      isRequired: true,
      validate: [{ type: validatorTypes.REQUIRED }],
      clearOnUnmount: true,
    },

    {
      component: componentTypes.SELECT,
      name: 'obj_storage_id',
      id: 'obj_storage_id',
      label: __('Choose cloud object storage'),
      isRequired: true,
      validate: [{ type: validatorTypes.REQUIRED }],
      clearOnUnmount: true,
      includeEmpty: true,
      loadOptions: () => storages,
      onChange: (value) => {
        setState({...state, obj_storage_id: value})
      },
    },

    {
      component: componentTypes.SELECT,
      name: 'bucket_id',
      key: `obj_storage_id-${state['obj_storage_id']}`,
      id: 'bucket_id',
      label: __('Choose storage bucket'),
      isRequired: true,
      validate: [{ type: validatorTypes.REQUIRED }],
      includeEmpty: true,
      clearOnUnmount: true,
      loadOptions: () => buckets,
    },

    {
      component: componentTypes.SELECT,
      name: 'timeout',
      id: 'timeout',
      label: __('Workflow max. timeout'),
      isRequired: true,
      initialValue: 3,
      options: Array.from(Array(24).keys()).map((h) => {return {label: (h+1) + " hours", value: (h+1)} }),
    },
  ]
}

function fieldsForPVC(state, setState, providers, storages, diskTypes, images, buckets)
{
  return [{
    component: componentTypes.SELECT,
    name: 'src_provider_id',
    id: 'src_provider_id',
    label: __('Choose source provider'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => providers,
    onChange: (value) => {
      setState({...state, src_provider_id: value})
    },
  },

  {
    component: componentTypes.SELECT,
    name: 'src_image_id',
    key: `src_provider_id-${state['src_provider_id']}`,
    id: 'src_image_id',
    label: __('Choose source image'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => images,
  },

  {
    component: componentTypes.SELECT,
    name: 'obj_storage_id',
    id: 'obj_storage_id',
    label: __('Choose transient storage'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => storages,
    onChange: (value) => {
      setState({...state, obj_storage_id: value})
    },
  },

  {
    component: componentTypes.SELECT,
    name: 'bucket_id',
    key: `obj_storage_id-${state['obj_storage_id']}`,
    id: 'bucket_id',
    label: __('Choose storage bucket'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => buckets,
  },

  {
    component: componentTypes.SELECT,
    name: 'disk_type_id',
    id: 'disk_type_id',
    label: __('Choose disk type'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => diskTypes,
  },

  {
    component: componentTypes.SELECT,
    name: 'timeout',
    id: 'timeout',
    label: __('Workflow max. timeout'),
    isRequired: true,
    initialValue: 3,
    options: Array.from(Array(24).keys()).map((h) => {return {label: (h+1) + " hours", value: (h+1)} }),
  },

  {
    component: componentTypes.CHECKBOX,
    name: 'keep_ova',
    id: 'keep_ova',
    label: __('Keep OVA file on completion'),
  }]
}

function fieldsForCOS(state, setState, storages, diskTypes, buckets)
{
  return [
  {
    component: componentTypes.SELECT,
    name: 'obj_storage_id_cos',
    id: 'obj_storage_id_cos',
    label: __('Choose cloud object storage'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => storages,
    onChange: (value) => {
      setState({...state, obj_storage_id: value})
    },
  },

  {
    component: componentTypes.SELECT,
    name: 'bucket_id_cos',
    key: `obj_storage_id-${state['obj_storage_id']}`,
    id: 'bucket_id_cos',
    label: __('Choose storage bucket'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => buckets,
  },

  {
    component: componentTypes.SELECT,
    name: 'disk_type_id_cos',
    id: 'disk_type_id_cos',
    label: __('Choose disk type'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => diskTypes,
  },

  {
    component: componentTypes.SELECT,
    name: 'timeout_cos',
    id: 'timeout_cos',
    label: __('Workflow max. timeout'),
    isRequired: true,
    initialValue: 3,
    options: Array.from(Array(24).keys()).map((h) => {return {label: (h+1) + " hours", value: (h+1)} }),
  },

  {
    component: componentTypes.CHECKBOX,
    name: 'keep_ova_cos',
    id: 'keep_ova_cos',
    label: __('Keep OVA file on completion'),
  }]
}

function default_fields(state, setState)
{
    return [{
        component: componentTypes.SELECT,
        name: 'provider_type',
        id: 'provider_type',
        label: __('Choose source provider type'),
        isRequired: true,
        includeEmpty: true,
        options: [
            { label: 'PowerVC', value: 'PowerVC' },
            { label: 'PowerVS', value: 'PowerVS' },
            { label: 'COS',     value: 'COS'     },
            { label: 'IBM AIX', value: 'AIX'     },
        ],

        onChange: (value) => {
          setState({state, provider_type: value})
      },
    },
  ]
}

function corresp_fields(state, setState, providers, storages, diskTypes, images, buckets)
{
  switch(state['provider_type']){
    case 'PowerVC':
      return fieldsForPVC(state, setState, providers, storages, diskTypes, images, buckets)
    case 'COS':
      return fieldsForCOS(state, setState, storages, diskTypes, buckets)
    case 'AIX':
      return fieldsForAIX(state, setState, storages, buckets)
    default:
      return []
  }
}


function createSchema(state, setState, providers, storages, diskTypes, images, buckets)
{
  var our_fields = [];

  our_fields = our_fields.concat(default_fields(state, setState, providers))
  our_fields = our_fields.concat(corresp_fields(state, setState, providers, storages, diskTypes, images, buckets))

  return { fields: our_fields }
};


export default createSchema;