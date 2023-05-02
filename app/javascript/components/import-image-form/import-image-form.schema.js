import React from 'react';
import { componentTypes, validatorTypes } from '@@ddf';


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
    key: `src_provider_id-${state['src_provider_id']}`,
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

function fieldsForCOS(state, setState, storages, diskTypes, buckets, objects)
{
  return [
  {
    component: componentTypes.SELECT,
    name: 'src_provider_id',
    id: 'src_provider_id',
    label: __('Choose cloud object storage'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => storages,
    onChange: (value) => {
      setState({...state, src_provider_id: value})
    },
  },

  {
    component: componentTypes.SELECT,
    name: 'cos_container_id',
    key: `cos_container_id-${state['src_provider_id']}`,
    id: 'cos_container_id',
    label: __('Choose storage bucket'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => buckets,
    onChange: (value) => {
      setState({...state, cos_container_id: value})
    },
  },

  {
    component: componentTypes.SELECT,
    name: 'src_image_id',
    key: `src_image_id-${state['src_provider_id']}-${state['cos_container_id']}`,
    id: 'src_image_id',
    label: __('Choose image object'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    clearOnUnmount: true,
    loadOptions: () => objects,
  },

  {
    component: componentTypes.SELECT,
    name: 'os_type',
    id: 'os_type',
    label: __('Choose image OS Type'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
    includeEmpty: true,
    options: [{label: "AIX", value: "aix"}, {label: "IBMi", value: "ibmi"}, {label: "Red Hat Enterprise Linux (RHEL)", value: "rhel"}, {label: "SUSE Linux Enterprise Server (SLES)", value: "sles"},],
  },

  {
    component: componentTypes.TEXT_FIELD,
    name: 'image_name',
    id: 'image_name',
    label: __('Custom image name'),
    isRequired: true,
    validate: [{ type: validatorTypes.REQUIRED }],
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
  }]
}

function default_fields(state, setState)
{
    return [{
        component: componentTypes.SELECT,
        name: 'src_provider_type',
        id: 'src_provider_type',
        label: __('Choose source provider type'),
        isRequired: true,
        includeEmpty: true,
        options: [{ label: 'PowerVC', value: 'ManageIQ::Providers::IbmPowerVc' },
        { label: 'COS', value: 'ManageIQ::Providers::IbmCloud::ObjectStorage' },],
        onChange: (value) => {
          setState({state, src_provider_type: value})
      },
    },
  ]
}

function corresp_fields(state, setState, providers, storages, diskTypes, images, buckets, objects)
{
  switch(state['src_provider_type']){
    case 'ManageIQ::Providers::IbmPowerVc':
      return fieldsForPVC(state, setState, providers, storages, diskTypes, images, buckets)
    case 'ManageIQ::Providers::IbmCloud::ObjectStorage':
      return fieldsForCOS(state, setState, storages, diskTypes, buckets, objects)
    default:
      return []
  }
}


function createSchema(state, setState, providers, storages, diskTypes, images, buckets, objects)
{
  var our_fields = [];

  our_fields = our_fields.concat(default_fields(state, setState, providers))
  our_fields = our_fields.concat(corresp_fields(state, setState, providers, storages, diskTypes, images, buckets, objects))

  return { fields: our_fields }
};


export default createSchema;
