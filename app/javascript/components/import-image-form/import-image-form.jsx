import React, { useMemo, useState } from "react";
import PropTypes from "prop-types";
import { connect } from "react-redux";
import MiqFormRenderer from '@@ddf';
import createSchema from './import-image-form.schema.js';

const API_PROVIDERS = '/api/providers';
const API_CLOUD_TEMPL = '/api/cloud_templates';
const API_COS_CONT = '/api/cloud_object_store_containers';
const API_COS_OBJ = '/api/cloud_object_store_objects';
const API_VOL_TYPES = '/api/cloud_volume_types';


const fetchProviders = (kind) => {
  return new Promise((resolve, reject) => {
      var options = []

      API.options(API_PROVIDERS).then(({data: {supported_providers}}) => {
          var provider_classes = supported_providers;

          API.get(API_PROVIDERS + '?expand=resources&attributes=id,name,type').then(({resources}) => {
              resources.forEach((provider) => {
                  var result = provider_classes.find(provider_class => provider_class['type'] === provider['type']);

                  if (typeof result !== typeof undefined && result['kind'] === kind)
                      options.push({value: provider['id'], label: provider['name']});
              })

              resolve(options);
          })
      })
  })
}

const fetchImages = (provider) => {
    return new Promise((resolve, reject) => {
        API.get(API_CLOUD_TEMPL + '?expand=resources&attributes=id,name&filter[]=ems_id=' + provider).then(({resources}) => {
            let options = resources.map(({id, name}) => ({value: id, label: name}));
            resolve(options);
        })
    })
}

const fetchBuckets = (provider) => {
    return new Promise((resolve, reject) => {
        API.get(API_COS_CONT + '?expand=resources&attributes=name,id&filter[]=ems_id=' + provider).then(({resources}) => {
            let options = resources.map(({id, name}) => ({value: id, label: name}));
            resolve(options);
        })
    })
}

const fetchObjects = (cloud_object_store_container_id) => {
    return new Promise((resolve, reject) => {
        API.get(API_COS_OBJ + '?expand=resources&attributes=name,id&filter[]=cloud_object_store_container_id='+ cloud_object_store_container_id).then(({resources}) => {
            let options = resources.map(({id, name}) => ({value: id, label: name}));
            resolve(options);
        })
    })
}

const fetchDiskTypes = (provider) => {
    return new Promise((resolve, reject) => {
        API.get(API_PROVIDERS + '/' + provider + '/cloud_volume_types?expand=resources&attributes=id,name').then(({resources}) => {
            let options = resources.map(({id, name}) => ({value: id, label: name}));
            resolve(options);
        })
    })
}

const ImportImageForm = ({ dispatch }) => {
    const [state, setState] = useState({});
    const providers = fetchProviders('cloud');

    const storages  = fetchProviders('storage');
    const diskTypes = fetchDiskTypes(ManageIQ.record.recordId);
    const images    = useMemo(() => fetchImages(state['src_provider_id']), [state['src_provider_id']]);
    const buckets   = useMemo(() => fetchBuckets(state['src_provider_id']), [state['src_provider_id']]);
    const objects   = useMemo(() => fetchObjects(state['cos_container_id']), [state['cos_container_id']]);

    const initialize = (formOptions) => {
        dispatch({ type: "FormButtons.init",        payload: { newRecord: true, pristine: true } });
        dispatch({ type: "FormButtons.customLabel", payload: __('Import') });
        dispatch({ type: 'FormButtons.callbacks',   payload: { addClicked: () => formOptions.submit() }});
    };

    const onSubmit = (values) => {
        API.post(API_CLOUD_TEMPL, {...values, action: 'import', "dst_provider_id": ManageIQ.record.recordId}).then(({ results }) => window.add_flash("Image Import Request Submitted!"));
    };

    const onCancel = () => {
        dispatch({ type: 'FormButtons.reset' });
    };

    return (<div id="ignore_form_changes"><MiqFormRenderer initialize={initialize} schema={createSchema(state, setState, providers, storages, diskTypes, images, buckets, objects)} showFormControls={false} onCancel={onCancel} onSubmit={onSubmit}/></div>)
};

ImportImageForm.propTypes = {
    dispatch: PropTypes.func.isRequired,
    closefunc: PropTypes.func.isRequired
};

ImportImageForm.defaultProps = {
    closefunc: () => { ManageIQ.redux.store.dispatch({ type: 'FormButtons.reset' }) }
};

export default connect()(ImportImageForm);
