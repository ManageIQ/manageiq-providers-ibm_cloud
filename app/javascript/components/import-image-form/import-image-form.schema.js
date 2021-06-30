import React from 'react';
import { componentTypes, validatorTypes } from '@@ddf';


const createSchema = (providers, images, storages, buckets, diskTypes, state, setState) => ({
  fields: [
    {
      component: componentTypes.SELECT,
      name: 'src_provider_id',
      id: 'src_provider_id',
      label: __('Choose source provider'),
      isRequired: true,
      validate: [{ type: validatorTypes.REQUIRED }],
      includeEmpty: true,
      loadOptions: () => providers,
      onChange: (value) => {setState({...state, src_provider_id: value})},
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
      loadOptions: () => storages,
      onChange: (value) => {setState({...state, obj_storage_id: value})},
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
      loadOptions: () => diskTypes,
    },

    {
      component: componentTypes.CHECKBOX,
      name: 'keep_ova',
      id: 'keep_ova',
      label: __('Keep OVA file on completion'),
    }
  ]
});

export default createSchema;